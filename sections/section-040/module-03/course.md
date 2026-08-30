# LDAP Client Integration with SSSD

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS005/tree/main/sections/section-040/module-03/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-040/module-03/playground
> astrona destroy sssd-client-playground
> ```

Modules 1 and 2 built a running, TLS-secured OpenLDAP server at `dc=example,dc=com`, populated with a `developers` group and a `lfcsuser` POSIX account. A directory nothing reads from is still just a database. This module closes the loop: configuring the same machine, acting now as a *client*, to treat that directory as the source of truth for identity and authentication — using `sssd`, the integration layer current distributions and the LFCS exam expect.

> *Prove NSS resolution with `getent` / `id` before you ever test a login — a broken auth config that also breaks local accounts can lock you out entirely.*

## Learning objectives

After this module you can:

- Explain what `sssd` provides over a direct `libnss-ldap`-style setup — caching, a daemon, retry / reconnect.
- Write `/etc/sssd/sssd.conf` with an `[sssd]` section and a matching `[domain/…]` section for an LDAP backend over StartTLS.
- Explain why `services`, `domains`, and the domain header name must line up, and what `id_provider` versus `auth_provider` mean.
- Set `sssd.conf` to mode `600` `root:root`, and explain the startup refusal when it is looser.
- Add `sss` to `/etc/nsswitch.conf` in the correct order, and explain why `files` first keeps local accounts safe.
- Verify NSS resolution with `getent` / `id` before attempting a login, and confirm `root` still resolves via `files`.

## Before you start

You should have a populated, TLS-secured LDAP server to point at — Modules 1 and 2 build exactly that, and the playground provisions their end state for you. You should be comfortable with `systemctl` / `journalctl` and editing config files. One term: **NSS** (Name Service Switch) is the glue that turns a username into a UID, a group name into a GID, and so on — `/etc/nsswitch.conf` decides which sources it asks and in what order.

Two commands do most of the verifying here. `getent` (read: *get entries*) asks NSS for a database record exactly the way the system does at runtime — `getent passwd lfcsuser` returns the same line a login would resolve — so it walks the `nsswitch.conf` chain including `sss` once that is wired. `sssctl` (read: *SSSD control*) is `sssd`'s own admin tool; `sssctl config-check` validates `sssd.conf`'s syntax *and* its file permissions without starting the daemon.

The playground VM already has:

- Modules 1-2's finished state: a TLS LDAP server on `127.0.0.1` serving `dc=example,dc=com`, with `ou=people`, `ou=groups`, a `developers` group (GID `5000`), and `uid=lfcsuser` (UID `10001`, home `/home/lfcsuser`, shell `/bin/bash`, password `LfcsLdap!2024`).
- The server's certificate at `/etc/ldap/certs/ldap-server.crt`.
- `sssd`, `sssd-ldap`, `libnss-sss`, `libpam-sss` **installed but unconfigured** — no `/etc/sssd/sssd.conf`, `nsswitch.conf` untouched, `sssd` not running.
- `pam_mkhomedir` enabled and SSH password auth on, so a first login works cleanly.

Open a shell on it with:

```sh
astrona ssh astro-sssd-client-playground
```

Every command block below runs **inside that VM**.

## Where this fits

This is the consumer end of Section 040 — it reads the POSIX attributes Module 2 wrote. The discipline it teaches (verify resolution before login; keep `root` on `files`) is the same defensive habit that applies to any PAM or NSS change, LDAP or not: never make a change that could break local login without a proven fallback path.

## Why SSSD, not direct NSS-to-LDAP

Older systems wired NSS straight to LDAP with modules like `libnss-ldap`. That talks to the directory synchronously on *every* lookup, with no cache. Every `getent`, every login, hits the server fresh — and a brief outage breaks resolution for everyone, including users who logged in five minutes ago.

`sssd` (read: *System Security Services Daemon*) sits between NSS/PAM and the directory as a real daemon. That buys three things: a local cache (a short outage does not lock out already-seen users), connection handling with retries instead of one synchronous attempt per lookup, and one config surface that can back onto LDAP, Kerberos, or Active Directory without the rest of the system noticing.

The packages: `sssd-ldap` is the LDAP backend provider; `libnss-sss` and `libpam-sss` are the NSS and PAM modules that let the C library and the PAM stack actually reach the running daemon. Without those last two, `sssd` can run perfectly and stay invisible.

> [!TIP]
> **Try it — nothing resolves yet, and that is expected**
>
> ```sh
> dpkg -l sssd sssd-ldap libnss-sss libpam-sss | grep '^ii'
> ls /etc/sssd/sssd.conf 2>&1
> getent passwd lfcsuser; echo "exit: $?"
> ```
>
> Expect something like:
>
> ```text
> ii  sssd            ...
> ii  sssd-ldap       ...
> ii  libnss-sss      ...
> ii  libpam-sss      ...
> ls: cannot access '/etc/sssd/sssd.conf': No such file or directory
> exit: 2
> ```
>
> Every package is installed, yet `getent passwd lfcsuser` returns nothing (exit `2` = not found). Installed is not integrated — there is no config and NSS has not been told to ask.

## The domain section

`sssd`'s behaviour lives in `/etc/sssd/sssd.conf`: an `[sssd]` section plus one `[domain/NAME]` section per identity source.

```ini
[sssd]
config_file_version = 2
services = nss, pam
domains = example.com

[domain/example.com]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://127.0.0.1
ldap_search_base = dc=example,dc=com
ldap_id_use_start_tls = true
ldap_tls_cacert = /etc/ldap/certs/ldap-server.crt
cache_credentials = True
```

The directives that trip up a first attempt:

- `services = nss, pam` activates the two front-ends. No `nss`, and `getent` / `id` never work no matter how right the domain section is. No `pam`, and login authentication never routes through `sssd`. Independent switches, both needed.
- `domains = example.com` names the active domain; the `[domain/example.com]` header must match it **exactly**, or the section is silently ignored.
- `id_provider` answers "where does user/group data come from"; `auth_provider` answers "where is a credential validated". This lab points both at LDAP; a real setup might use LDAP for identity and Kerberos for auth. The split in the format is deliberate.
- `ldap_id_use_start_tls = true` upgrades the connection the way `ldapsearch -ZZ` did, because Module 1 enforced TLS. `ldap_tls_cacert` points at a local copy of the server's cert so `sssd` trusts the self-signed cert instead of rejecting the handshake. (For quick troubleshooting only, `ldap_tls_reqcert` can be relaxed — trusting the specific cert is the correct fix, not disabling verification.)
- `cache_credentials = True` is the payoff: a previously-authenticated user can still log in from cache during a brief outage.

> [!TIP]
> **Try it — write the file and syntax-check it**
>
> ```sh
> sudo install -d -m 711 /etc/sssd
> sudo tee /etc/sssd/sssd.conf >/dev/null <<'EOF'
> [sssd]
> config_file_version = 2
> services = nss, pam
> domains = example.com
>
> [domain/example.com]
> id_provider = ldap
> auth_provider = ldap
> ldap_uri = ldap://127.0.0.1
> ldap_search_base = dc=example,dc=com
> ldap_id_use_start_tls = true
> ldap_tls_cacert = /etc/ldap/certs/ldap-server.crt
> cache_credentials = True
> EOF
> sudo chmod 600 /etc/sssd/sssd.conf
> sudo chown root:root /etc/sssd/sssd.conf
> sudo sssctl config-check
> ```
>
> Expect something like:
>
> ```text
> Issues identified by validators: 0
> Messages generated during config merge: 0
> Used configuration snippet files: 0
> ```
>
> `sssctl config-check` parses the file and the permissions and reports zero issues. A misspelled directive or a domain-header mismatch would show up here as a validator issue.

## The permission check SSSD performs on itself

`sssd.conf` holds connection details that should not be world-readable, and `sssd` does not just hope you remember — it checks at startup and refuses to run against a loose file rather than proceed insecurely. `600`, owned `root:root`, is the required state.

> [!TIP]
> **Try it — loosen the file and watch sssd refuse**
>
> ```sh
> sudo chmod 644 /etc/sssd/sssd.conf
> sudo systemctl restart sssd; echo "restart exit: $?"
> sudo journalctl -u sssd -n 5 --no-pager | grep -i perm
> sudo chmod 600 /etc/sssd/sssd.conf
> ```
>
> Expect something like:
>
> ```text
> restart exit: 1
> ... File ownership and permissions check failed. Expected root:root and 0600.
> ```
>
> Mode `644` makes the restart fail with an explicit ownership/permissions message — nothing to do with `ldap_uri` or the domain section. This failure mode surprises people because it looks unrelated to the config content. Restoring `600` clears it.

## Telling NSS to actually ask

None of the above matters until NSS consults `sssd`. `/etc/nsswitch.conf` lists, per database, an ordered set of sources. The `passwd` and `group` lines need `sss` added:

```text
passwd:         files sss
group:          files sss
```

The **order** is the point. NSS checks sources left to right, so a lookup for `root` is satisfied by `files` (`/etc/passwd`) before `sss` is ever consulted — completely independent of whether `sssd` or LDAP is healthy. That is the entire reason a misconfigured LDAP integration does not lock you out. `sss` before `files` would be the dangerous ordering.

> [!TIP]
> **Try it — wire NSS, start sssd, and resolve the user**
>
> ```sh
> sudo sed -i -E '/^(passwd|group):/ s/$/ sss/' /etc/nsswitch.conf
> grep -E '^(passwd|group):' /etc/nsswitch.conf
> sudo systemctl enable --now sssd
> getent passwd lfcsuser
> getent group developers
> ```
>
> Expect something like:
>
> ```text
> passwd:         files systemd sss
> group:          files systemd sss
> lfcsuser:*:10001:5000:LFCS User:/home/lfcsuser:/bin/bash
> developers:*:5000:
> ```
>
> With `sss` appended (after `files`) and `sssd` running, `getent passwd lfcsuser` now returns a full `passwd`-style line built from Module 2's POSIX attributes — `sssd` queried LDAP over StartTLS and NSS handed the result back. If it were missing `sss`, this would still return nothing regardless of how correct `sssd.conf` is.

## Verify in order — resolution, then login

There is a correct testing order; skipping ahead wastes time on the wrong layer.

**First**, prove NSS resolution, no authentication involved:

```sh
getent passwd lfcsuser
getent group developers
id lfcsuser
```

`getent` walks the exact source chain in `nsswitch.conf`; a clean result proves the whole identity path end to end. `id` additionally confirms group-membership resolution, which `getent passwd` alone would not catch.

**Then**, and only then, test an actual login — from a **second** session, keeping your privileged one open:

```sh
ssh lfcsuser@127.0.0.1
```

**Finally**, confirm the thing that must never have changed:

```sh
getent passwd root
id root
```

`root` resolves via `files`, per the ordering above, no matter what state `sssd` is in. This check proves the integration is additive, not a replacement — and it is worth re-running any time you touch PAM or NSS.

> [!TIP]
> **Try it — resolution, a real LDAP login, and root untouched**
>
> ```sh
> id lfcsuser
> sshpass -p 'LfcsLdap!2024' ssh -o StrictHostKeyChecking=no lfcsuser@127.0.0.1 'whoami; pwd'
> getent passwd root
> id root
> ```
>
> Expect something like:
>
> ```text
> uid=10001(lfcsuser) gid=5000(developers) groups=5000(developers)
> lfcsuser
> /home/lfcsuser
> root:x:0:0:root:/root:/bin/bash
> uid=0(root) gid=0(root) groups=0(root)
> ```
>
> `id lfcsuser` resolves UID, GID, and group from LDAP. The `ssh` login authenticates `lfcsuser` against the directory (PAM → `sssd` → LDAP bind) and `pam_mkhomedir` creates `/home/lfcsuser` on the way in. `root` still resolves from `/etc/passwd` with `x` in the password field — the local account path is completely unaffected. (`sshpass` is only in the playground for a non-interactive demo; normally you type the password.)

> [!WARNING]
> **Common pitfalls — SSSD client integration**
>
> - `sssd.conf` perfect, `getent passwd lfcsuser` still empty — check `/etc/nsswitch.conf` first. No `sss` on the `passwd` line means NSS never asks `sssd`.
> - `[domain/example.com]` header not matching `domains = example.com` — the section is silently ignored, no error.
> - `sssd.conf` at `644` or group-readable — `sssd` refuses to start with a permissions error that looks unrelated to the config content. `chmod 600`, `chown root:root`.
> - `sss` before `files` in `nsswitch.conf` — a directory outage can now break `root` resolution. `files` always first.
> - Testing login before `getent` / `id` — conflates identity resolution and PAM auth; you cannot tell which failed.
> - Self-signed cert rejected — set `ldap_tls_cacert` to a local copy of the server cert. Do not disable verification as the "fix".
