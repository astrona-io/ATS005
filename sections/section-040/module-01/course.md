# LDAP Server Installation & TLS

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS005/tree/main/sections/section-040/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-040/module-01/playground
> astrona destroy ldap-server-tls-playground
> ```

Before any host can bind, search, or authenticate against a central directory, that directory has to exist: installed, given a namespace of its own, and wrapped in encryption so a bind password never crosses the network in the clear. This module builds exactly that — from a running-but-unconfigured `slapd` to a TLS-capable, still-empty OpenLDAP server serving `dc=example,dc=com`. The next module fills it with data; the one after connects a client. Here the job is standing the server up correctly.

> *`slapd` running is not the same as TLS working — a directory is "done" only once an encrypted handshake is verified to negotiate, not merely configured.*

## Learning objectives

After this module you can:

- Explain why modern OpenLDAP has no `slapd.conf`, and change `cn=config` with `ldapmodify` over `ldapi:///` and SASL EXTERNAL.
- Set a server's base DN, admin bind DN, and hashed admin password on the `mdb` database entry.
- Generate a password hash with `slappasswd`, and explain why a plaintext `olcRootPW` is a credential leak.
- Make a TLS key readable by the `openldap` service account and wire the certificate into `cn=config`.
- Distinguish StartTLS on port 389 from native LDAPS on port 636, and enable the 636 listener.
- Verify TLS at the transport layer with `openssl s_client` and at the LDAP layer with `ldapsearch -ZZ`.

## Before you start

You should be comfortable with `systemctl`, installing packages, editing config files, and reading `ss` output. It helps to know that TLS needs a certificate plus a private key and that a "handshake" is the negotiation that sets up the encrypted channel. One term used throughout: a **DN** (Distinguished Name) is a unique, path-like name for an entry in the directory tree, read right-to-left from the root — `cn=admin,dc=example,dc=com` sits under `dc=example,dc=com`. **DC** is "domain component"; `dc=example,dc=com` is just the DNS name `example.com` written as a tree root.

The playground VM already has:

- `slapd` (the OpenLDAP daemon) and `ldap-utils` installed; `slapd` running on port `389` with only the package defaults.
- A self-signed certificate and key at `/etc/ldap/certs/ldap-server.crt` / `.key`, owned by the `openldap` service account, with `CN=localhost` and SANs for `localhost` and `127.0.0.1`.
- Port `636` **not** listening yet.

Open a shell on it with:

```sh
astrona ssh astro-ldap-server-tls-playground
```

Every command block below runs **inside that VM**.

## Where this fits

This is the foundation the rest of Section 040 stands on: Module 2 writes users and groups into the tree you name here, and Module 3 points `sssd` at the TLS endpoint you verify here. The certificate mechanics themselves belong to the course's PKI / OpenSSL material — this module takes the cert as given and focuses on wiring it into the daemon and proving it negotiates.

## The directory that is not a file

If you have configured other Linux services, your instinct on meeting `slapd` (read: *Standalone LDAP Daemon*) is to find one config file, edit it, and restart. That fails here. Modern OpenLDAP does not keep its running configuration in a flat `slapd.conf`. It stores configuration as a live, LDAP-queryable tree rooted at `cn=config` — often called **OLC** (On-Line Configuration). Every setting — the base DN served, the admin identity, the TLS paths, the listening protocols — is an LDAP entry with attributes inside that tree.

The payoff: configuration can change without a restart (`slapd` re-reads its own tree), is protected by the same access controls as directory data, and is inspected with the same tools you use for ordinary directory data. Those tools are a family, all named `ldap` + the operation they perform and all taking the same connection flags (`-H` host URI, `-x` simple bind, `-D` bind DN, `-W` prompt for the bind password, `-Y` SASL mechanism, `-Z`/`-ZZ` StartTLS): `ldapsearch` reads entries, `ldapmodify` changes them, `ldapadd` creates them (Module 2), `ldappasswd` sets a password, `ldapwhoami` reports who a bind authenticated as. Learn the flags once and every command in the family reads the same way. The cost of the config-as-tree model: every configuration change is itself an LDAP operation. You write a small **LDIF** (LDAP Data Interchange Format) file describing what should change and apply it with `ldapmodify` against `cn=config`, authenticating over a local-only channel: the `ldapi:///` UNIX socket combined with SASL's `EXTERNAL` mechanism. `-Y EXTERNAL -H ldapi:///` tells the client "authenticate as my OS identity (root, via the socket's peer credentials), not a bind DN and password" — `slapd` treats a local root process reaching it this way as administrative over `cn=config`.

One more tool before the first checkpoint: `ss` (read: *socket statistics* — the modern replacement for `netstat`) lists network sockets. `ss -tlnp` reads as **t**CP sockets, **l**istening only, **n**umeric ports (no name lookup), with the owning **p**rocess — the quickest way to confirm which ports `slapd` has open.

> [!TIP]
> **Try it — the server is up, and its config is a tree**
>
> ```sh
> systemctl is-active slapd
> sudo ss -tlnp | grep -E ':389|:636'
> sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config -LLL dn
> ```
>
> Expect something like:
>
> ```text
> active
> LISTEN 0  1024  *:389  *:*  users:(("slapd",pid=800,fd=8))
> dn: cn=config
> dn: cn=schema,cn=config
> dn: cn={0}core,cn=schema,cn=config
> dn: olcDatabase={-1}frontend,cn=config
> dn: olcDatabase={0}config,cn=config
> dn: olcDatabase={1}mdb,cn=config
> ```
>
> Port `389` is listening, `636` is not (yet). The `ldapsearch` output is the *configuration itself*, returned as directory entries — `olcDatabase={1}mdb,cn=config` is the one that backs your actual data. `-LLL` just trims comments and version noise from the output.

## Claiming a namespace and an admin identity

The base DN this server is authoritative for, and the identity allowed to write under it, live on that `olcDatabase={1}mdb,cn=config` entry as three attributes: `olcSuffix` (the base DN), `olcRootDN` (the admin bind DN), and `olcRootPW` (the admin password, as a hash). The numeric index can differ between installs; `sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcMdbConfig)" dn` shows which entry it is on your system.

Never write a plaintext password. `slappasswd` (read: *slap password* — it makes a hash `slapd` can store) prompts for the password once and prints a salted `{SSHA}` hash suitable to drop straight into an LDIF. LDIF files get pasted into tickets and committed by accident; a plaintext `olcRootPW` in one is a permanent leak, a hash is not.

The modify LDIF has a fixed shape: a `dn:` naming the target entry, `changetype: modify`, then one or more `replace:` blocks separated by a line containing only `-`.

```sh
HASH=$(slappasswd -s 'LdapRoot!2024')
cat > /tmp/set-suffix.ldif << EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
-
replace: olcRootDN
olcRootDN: cn=admin,dc=example,dc=com
-
replace: olcRootPW
olcRootPW: ${HASH}
EOF
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set-suffix.ldif
```

(`slappasswd -s '<pw>'` takes the password as an argument for a scripted flow; run `slappasswd` with no `-s` to be prompted instead and keep it out of shell history.) `olcRootDN` / `olcRootPW` define an identity with unrestricted access to this one database, independent of any regular entry — it is what Module 2 uses to add users.

> [!TIP]
> **Try it — name the directory, then read the setting back**
>
> ```sh
> HASH=$(slappasswd -s 'LdapRoot!2024')
> printf 'dn: olcDatabase={1}mdb,cn=config\nchangetype: modify\nreplace: olcSuffix\nolcSuffix: dc=example,dc=com\n-\nreplace: olcRootDN\nolcRootDN: cn=admin,dc=example,dc=com\n-\nreplace: olcRootPW\nolcRootPW: %s\n' "$HASH" > /tmp/set-suffix.ldif
> sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set-suffix.ldif
> sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config -LLL "(olcSuffix=*)" olcSuffix olcRootDN
> ```
>
> Expect something like:
>
> ```text
> modifying entry "olcDatabase={1}mdb,cn=config"
> dn: olcDatabase={1}mdb,cn=config
> olcSuffix: dc=example,dc=com
> olcRootDN: cn=admin,dc=example,dc=com
> ```
>
> The `modifying entry` line means the change applied with no restart. The read-back shows `slapd` is now authoritative for `dc=example,dc=com` with `cn=admin,dc=example,dc=com` as its admin. `olcRootPW` is not shown — it is stored hashed.

## A certificate the daemon can actually read

`slapd` does **not** run as root. It runs as an unprivileged service account — `openldap` on Debian/Ubuntu, often `ldap` on RHEL-family (`ps -o user= -C slapd` confirms). That account must be able to *read* the private key, or TLS setup fails at startup. A world-readable key is a security mistake; a key readable only by `root` when `slapd` runs as `openldap` is the equally common opposite mistake, and it produces a startup failure that looks like a bad certificate rather than a permission problem.

The playground's key is already `openldap:openldap`, mode `640`. The pattern, for reference:

```sh
sudo chown openldap:openldap /etc/ldap/certs/ldap-server.key /etc/ldap/certs/ldap-server.crt
sudo chmod 640 /etc/ldap/certs/ldap-server.key
sudo chmod 644 /etc/ldap/certs/ldap-server.crt
```

> [!TIP]
> **Try it — who runs slapd, and can it read the key**
>
> ```sh
> ps -o user= -C slapd
> ls -l /etc/ldap/certs/
> sudo -u openldap cat /etc/ldap/certs/ldap-server.key >/dev/null && echo "openldap CAN read the key"
> ```
>
> Expect something like:
>
> ```text
> openldap
> -rw-r--r-- 1 openldap openldap 1391 Aug 30 12:00 ldap-server.crt
> -rw-r----- 1 openldap openldap 1704 Aug 30 12:00 ldap-server.key
> openldap CAN read the key
> ```
>
> `slapd` runs as `openldap`; the key is owned by `openldap` and group-readable but not world-readable; the explicit read test as that user succeeds. If that last line failed, TLS would break at the next restart — and the cause would be this, not the cert.

## Wiring the certificate into cn=config

TLS is a property of the daemon, not of one database, so this modify targets `cn=config` directly. Three attributes: `olcTLSCertificateFile`, `olcTLSCertificateKeyFile`, and `olcTLSCACertificateFile` — for a self-signed cert the CA file points back at the cert itself, because it is its own trust anchor.

```sh
cat > /tmp/set-tls.ldif << 'EOF'
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/certs/ldap-server.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/certs/ldap-server.key
-
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ldap/certs/ldap-server.crt
EOF
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set-tls.ldif
sudo systemctl restart slapd
```

A restart is needed here (unlike most `cn=config` changes) because the TLS listener is set up at daemon startup. Restarting `slapd` on this single-VM playground is safe; on a production directory serving live clients, treat it as a brief outage and schedule it.

> [!TIP]
> **Try it — apply the TLS attributes and confirm they stuck**
>
> ```sh
> printf 'dn: cn=config\nchangetype: modify\nreplace: olcTLSCertificateFile\nolcTLSCertificateFile: /etc/ldap/certs/ldap-server.crt\n-\nreplace: olcTLSCertificateKeyFile\nolcTLSCertificateKeyFile: /etc/ldap/certs/ldap-server.key\n-\nreplace: olcTLSCACertificateFile\nolcTLSCACertificateFile: /etc/ldap/certs/ldap-server.crt\n' > /tmp/set-tls.ldif
> sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set-tls.ldif
> sudo systemctl restart slapd
> sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config -LLL "(cn=config)" olcTLSCertificateFile olcTLSCertificateKeyFile
> ```
>
> Expect something like:
>
> ```text
> modifying entry "cn=config"
> dn: cn=config
> olcTLSCertificateFile: /etc/ldap/certs/ldap-server.crt
> olcTLSCertificateKeyFile: /etc/ldap/certs/ldap-server.key
> ```
>
> `slapd` came back up after the restart (if it did not, `journalctl -u slapd -n 30` would show a cert/key/permission reason). The attributes read back with the paths you set — the daemon now has a TLS identity.

## StartTLS on 389, or native LDAPS on 636

OpenLDAP offers encryption two ways, and the distinction matters for troubleshooting later.

- **Native LDAPS**, port 636, wraps the whole connection in TLS from the first byte — like HTTPS. The client knows the channel is encrypted before it speaks any LDAP.
- **StartTLS**, on the standard port 389, starts as a plain connection and upgrades in place, mid-conversation, via an LDAP extended operation. Most modern tooling (`ldapsearch -Z`/`-ZZ`, `sssd`) defaults to this.

A production directory commonly offers both. The 636 listener is enabled by adding `ldaps:///` to `slapd`'s list of listening URLs — on Debian/Ubuntu that is `SLAPD_SERVICES` in `/etc/default/slapd`:

```sh
sudo sed -i 's|^SLAPD_SERVICES=.*|SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"|' /etc/default/slapd
sudo systemctl restart slapd
```

Three listeners, three jobs: `ldap:///` is plain/StartTLS-capable 389, `ldaps:///` is native TLS on 636, `ldapi:///` is the local socket used for `cn=config` admin.

> [!TIP]
> **Try it — bring up the 636 listener**
>
> ```sh
> grep SLAPD_SERVICES /etc/default/slapd
> sudo sed -i 's|^SLAPD_SERVICES=.*|SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"|' /etc/default/slapd
> sudo systemctl restart slapd
> sudo ss -tlnp | grep -E ':389|:636'
> ```
>
> Expect something like:
>
> ```text
> SLAPD_SERVICES="ldap:/// ldapi:///"
> LISTEN 0 1024 *:389 *:* users:(("slapd",pid=1200,fd=8))
> LISTEN 0 1024 *:636 *:* users:(("slapd",pid=1200,fd=9))
> ```
>
> Before the edit, only `ldap:///` and `ldapi:///` were listed; after, `636` joins `389` in the `ss` output. A typo in `SLAPD_SERVICES` would stop `slapd` starting — check `systemctl status slapd` if the last line is missing `636`.

## Proving it, not assuming it

A config that "should" work is not one that does. Verify at two layers, because they fail independently.

The **transport layer** — does a raw TLS handshake complete? `openssl s_client` is OpenSSL's built-in TLS *client* for exactly this: it opens a raw encrypted connection to a host:port, prints the certificate the server presents and the handshake result, then waits for input — `</dev/null` feeds it nothing so it reports and exits. `-connect host:port` is the target; `-showcerts` dumps the full chain.

```sh
openssl s_client -connect 127.0.0.1:636 -showcerts </dev/null
```

A full certificate chain and a `Verify return code:` line mean the handshake worked. `Verify return code: 18 (self-signed certificate)` is *expected and fine* here — it says the cert is not signed by a public CA, not that the handshake failed.

The **LDAP application layer** — does StartTLS actually negotiate through `slapd`?

```sh
ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base
```

`-x` is simple (non-SASL) auth; `-b "" -s base` reads just the root DSE (a tiny always-present entry). `-ZZ` *requires* StartTLS to succeed before the search runs and aborts with an error otherwise — so any result here is real proof the encrypted upgrade worked end to end. If `openssl s_client` succeeds but this fails, the transport is fine and the fault is in how `cn=config`'s TLS attributes wire to the StartTLS operation, or in client trust — not the cert files.

> [!TIP]
> **Try it — both layers, in order**
>
> ```sh
> openssl s_client -connect 127.0.0.1:636 </dev/null 2>/dev/null | grep -E 'subject=|Verify return code'
> ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base namingContexts
> ```
>
> Expect something like:
>
> ```text
> subject=CN = localhost
> Verify return code: 18 (self-signed certificate)
> dn:
> namingContexts: dc=example,dc=com
> ```
>
> The handshake on 636 completes (return code 18 is the expected self-signed result). The `-ZZ` search forced a StartTLS upgrade on 389 and still returned the root DSE, whose `namingContexts` echoes the base DN you set earlier. The server is installed, serving `dc=example,dc=com`, TLS-verified on both paths — and completely empty. That is where Module 2 begins.

> [!WARNING]
> **Common pitfalls — LDAP server + TLS**
>
> - Reaching for `vi /etc/ldap/slapd.conf` — there is no such file on a modern install. Change `cn=config` with `ldapmodify -Y EXTERNAL -H ldapi:///`.
> - Plaintext `olcRootPW` — always `slappasswd` first; the hash goes in the LDIF, the plaintext never touches disk.
> - Key readable only by root while `slapd` runs as `openldap` — TLS fails at startup and the error misleads you toward the cert. Check `ps -o user= -C slapd` and the key's ownership/mode.
> - Forgetting the restart after the TLS modify — the listener is built at startup, so TLS attributes alone do not open 636.
> - Typo in `SLAPD_SERVICES` — `slapd` will not start. `systemctl status slapd` and `journalctl -u slapd` show why.
> - Treating `openssl s_client` success as full proof — it only proves transport. `ldapsearch -ZZ` is what proves StartTLS negotiates through `slapd`.
