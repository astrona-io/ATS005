# Module 3: LDAP Client Integration with SSSD

> *Prove NSS resolution with `getent`/`id` before you ever test a login — a broken auth config that also breaks local accounts can lock you out entirely.*

Modules 1 and 2 built something real: a running, TLS-secured OpenLDAP server at `dc=example,dc=com`, populated with a `developers` group and a `lfcsuser` POSIX account. A directory that nothing ever reads from is still just a database. This module closes the loop — configuring the very same machine, acting now as a client, to treat that directory as a source of truth for identity and authentication, using `sssd`, the modern integration layer that current LFCS material and modern distributions expect.

---

## Part I: Why SSSD, Not Direct NSS-to-LDAP

Older systems wired NSS directly to LDAP using modules like `libnss-ldap` or `nss-pam-ldapd`. That approach talks to the directory synchronously, on every single lookup, with no caching layer in between. Every `getent` call, every login attempt, hits the LDAP server fresh — and if that server is even briefly unreachable, resolution simply fails for everyone, including users who authenticated successfully five minutes earlier.

`sssd` — the System Security Services Daemon — sits between NSS/PAM and the directory as an actual daemon, not a passive library. That buys three concrete things: local caching (so a brief LDAP outage doesn't lock out users already seen), connection handling with retries instead of a single synchronous attempt per lookup, and a single consistent configuration surface that can back onto LDAP, Kerberos, or Active Directory without changing how the rest of the system talks to it. This is why `sssd` is the tool this course teaches, and the one you should expect on the exam.

Install it alongside the NSS and PAM modules that let the rest of the system actually talk to it:

```bash
sudo apt install -y sssd sssd-ldap libnss-sss libpam-sss
```

(RHEL/Fedora-family equivalent: `sudo dnf install -y sssd sssd-ldap`.) `sssd-ldap` is the LDAP-backend provider plugin; `libnss-sss` and `libpam-sss` are the actual NSS and PAM modules that let the C library and the PAM stack reach the running `sssd` daemon over its local socket. Without these two packages specifically installed, `sssd` can be running perfectly and still be invisible to the rest of the system.

---

## Part II: The Domain Section

`sssd`'s behavior is defined in `/etc/sssd/sssd.conf`, structured as an `[sssd]` section plus one `[domain/NAME]` section per identity source:

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

A few of these directives are easy to skim past and are exactly where a first attempt tends to go wrong.

`services = nss, pam` activates the two front-ends `sssd` can expose. Without `nss` here, `getent`/`id` never work, no matter how correct the domain section below is. Without `pam`, interactive login authentication never routes through `sssd` either — these are independent switches, and both are needed for a working end-to-end integration.

`domains = example.com` names which domain section(s) are active; the `[domain/example.com]` header must match this name exactly, or the section is silently ignored.

`id_provider` and `auth_provider` are conceptually separate settings, even though this configuration points both at the same LDAP backend. `id_provider` answers "where does user/group data come from"; `auth_provider` answers "where is a credential actually validated." A more complex real-world setup might use LDAP for identity and Kerberos for authentication — this course's single-VM lab keeps both on LDAP for clarity, but the separation in the config format is intentional and worth recognizing.

`ldap_uri = ldap://127.0.0.1` and `ldap_search_base = dc=example,dc=com` point at exactly the server and base DN Modules 1 and 2 built — every lab in this course runs the "server" and the "client" on the same machine, so the connection target is always loopback, never a second host. Because Module 1 enforced TLS on this server, `ldap_id_use_start_tls = true` upgrades the connection the same way `ldapsearch -ZZ` did, and `ldap_tls_cacert` points at a local copy of the server's own certificate so `sssd` actually trusts a self-signed cert instead of rejecting the handshake outright. (For quick troubleshooting only — never as a permanent setting — `ldap_tls_reqcert` can be relaxed; trusting the specific certificate via `ldap_tls_cacert` is the correct fix, not disabling verification.)

`cache_credentials = True` is the concrete payoff of choosing `sssd` over a direct NSS-to-LDAP module in the first place: a user who has authenticated before can still log in from `sssd`'s local cache during a brief directory outage.

---

## Part III: The Permission Check SSSD Performs on Itself

`sssd.conf` frequently contains connection details that should not be world-readable, and `sssd` does not simply hope administrators remember to lock it down — it checks at startup and refuses to run against a loosely-permissioned file rather than proceeding insecurely:

```bash
sudo chown root:root /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf
```

`600`, owned by `root:root`, is the expected and required state. Anything looser — `644`, group-readable, world-readable — causes `sssd` to fail at startup with a permission-related error in its logs. This failure mode surprises people specifically because it looks unrelated to the domain configuration itself; the fix has nothing to do with `ldap_uri` or `ldap_search_base` and everything to do with `ls -l` on the config file.

---

## Part IV: Telling NSS to Actually Ask

None of the above matters if NSS never consults `sssd` in the first place. `/etc/nsswitch.conf` lists, per database, an ordered set of sources to check. Change the relevant lines:

```
passwd: files
group:  files
```

to:

```
passwd: files sss
group:  files sss
```

This single edit is where "I configured `sssd.conf` perfectly and nothing works" most often actually goes wrong. If `sss` is missing from these lines, `getent passwd lfcsuser` returns nothing — not because `sssd` or LDAP is broken, but because NSS's lookup chain never reaches `sssd` at all, regardless of how correct the daemon's own configuration is.

Notice also the *order*: `files` comes first, `sss` second. NSS checks sources left to right. This ordering is precisely why local accounts are safe: a lookup for `root` is satisfied by `files` — `/etc/passwd` — before `sss` is ever consulted, completely independent of whether `sssd` or the LDAP backend is healthy at that moment. This is not an incidental detail; it is the entire reason a misconfigured LDAP integration does not lock you out of the box entirely.

Start (and enable) the service once the config and `nsswitch.conf` are both in place:

```bash
sudo systemctl enable --now sssd
sudo systemctl status sssd
sudo journalctl -u sssd -n 50 --no-pager
```

If Part III's permissions were wrong, this is where it surfaces — check the log for an explicit permission failure before assuming the domain configuration itself is at fault.

---

## Part V: Verify in Order — Resolution, Then Login

There is a correct order to testing this integration, and skipping ahead wastes time chasing the wrong layer.

**First**, prove NSS resolution, with no authentication involved at all:

```bash
getent passwd lfcsuser
getent group developers
id lfcsuser
```

`getent` walks the exact same source chain configured in `nsswitch.conf` — a correct result here proves the entire identity path works end to end: NSS asked `sss`, `sssd` queried LDAP, and the POSIX attributes from Module 2 (`uidNumber`, `gidNumber`, `homeDirectory`, `loginShell`) came back correctly. `id` goes one step further and confirms group membership resolution alongside the passwd entry — a check `getent passwd` alone would not necessarily catch on its own.

Only once both of these come back clean should interactive login even be attempted. Testing a login first conflates two separate failure domains — identity resolution and PAM authentication — and makes it much harder to tell which one actually broke if something goes wrong.

**Then**, and only then, test an actual login — from a **second**, separate session, keeping your original privileged session open:

```bash
ssh lfcsuser@127.0.0.1
```

**Finally**, confirm the one thing that must never have changed throughout any of this:

```bash
getent passwd root
id root
```

`root` resolves via `files`, per the `nsswitch.conf` ordering from Part IV, completely independent of `sssd`'s state — whether it is running perfectly, misconfigured, or not running at all. This is the check that proves the LDAP integration is additive, not a replacement for local accounts, and it is the check most worth running again any time you change PAM or NSS configuration in production.

---

## Self-Check and Verification

Test your understanding before attempting the lab:
1.  **Why SSSD**: What concrete capability does `sssd` provide over a direct `libnss-ldap`-style setup, beyond "it's more modern"? *(Answer: local caching and connection handling — a brief LDAP outage doesn't immediately break resolution or already-authenticated logins.)*
2.  **NSS Wiring**: If `sssd.conf` is configured correctly and the service is running, but `getent passwd lfcsuser` still returns nothing, what is the first file to check, and why? *(Answer: `/etc/nsswitch.conf` — if the `passwd` line doesn't include `sss`, NSS never queries SSSD at all, regardless of how correct `sssd.conf` is.)*
3.  **Verification Order**: Why check `getent`/`id` before attempting an interactive login? *(Answer: They isolate NSS/identity resolution from PAM/authentication — testing login first makes it hard to tell which layer actually failed.)*
4.  **Local Account Safety**: Why does `root` keep working no matter what happens to the LDAP configuration? *(Answer: `nsswitch.conf` lists `files` before `sss`, so local accounts resolve from `/etc/passwd` first and never need to reach the LDAP-backed source at all.)*
