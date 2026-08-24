# Module 1: LDAP Server Installation & TLS

> *Directory data and bind passwords cross the wire in cleartext by default — a directory server is not "done" the moment `slapd` is running, only once TLS is actually verified to negotiate, not merely configured.*

Every LDAP client integration you will ever build has to point at something real. Before any host can bind, search, or authenticate against a central directory, that directory has to exist: installed, given a namespace of its own, and wrapped in encryption so that a bind password never travels the network in the clear. This chapter builds exactly that — from a blank virtual machine to a running, TLS-capable, still-empty OpenLDAP server. The next module fills it with data; the module after that connects a client to it. This one is about standing the server up correctly the first time.

---

## Part I: The Directory That Isn't a File

If you have configured other Linux services before, your instinct on meeting `slapd` — the OpenLDAP daemon — will be to look for a single configuration file, edit it with `vi`, and restart the service. That instinct will fail you here, and understanding *why* is the single most important idea in this module.

Modern OpenLDAP does not store its running configuration in a flat `slapd.conf` text file. Instead, it stores configuration as a live, LDAP-queryable tree rooted at `cn=config`. This is often called **OLC** ("On-Line Configuration"). Every setting — the base DN this server serves, the admin identity, the TLS certificate paths, the listening protocols — is itself an LDAP entry with attributes, sitting inside this special tree, right alongside (but administratively separate from) the actual directory data.

Why go to this trouble? Because a tree that lives inside the running server can be:
- **Changed without a restart.** `slapd` re-reads its own configuration the moment you modify it, the same way it would notice a new user entry appear.
- **Secured with the same access controls as regular data.** Who is allowed to view or change TLS settings is itself an LDAP authorization question, not a filesystem permission question.
- **Queried and audited using the exact same tools** — `ldapsearch`, `ldapmodify` — you already use for ordinary directory data.

The practical consequence: every configuration change in this module is an LDAP operation. You do not open a text editor and change a line. You write a small LDIF file describing exactly what should change, and you apply it with `ldapmodify` against the `cn=config` tree, authenticating over a special local channel. That channel is the `ldapi:///` UNIX socket, combined with SASL's `EXTERNAL` mechanism:

```bash
sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=config" "(olcSuffix=*)" olcSuffix olcRootDN
```

`-Y EXTERNAL -H ldapi:///` tells the LDAP client: authenticate using my own operating-system identity (root, via the UNIX socket's peer credentials) rather than a bind DN and password. `slapd` trusts a local root process reaching it this way as equivalent to administrative access over `cn=config` — no bind password needed at all. This is the standard way to administer OLC, and you will use it repeatedly in this module.

---

## Part II: Installing the Daemon

Install the server daemon and the client utilities together:

```bash
sudo apt update && sudo apt install -y slapd ldap-utils
```

`slapd` is the directory daemon itself. `ldap-utils` supplies every command-line tool you will use throughout this section and the next: `ldapsearch`, `ldapadd`, `ldapmodify`, `ldappasswd`, and `slappasswd`. (On a RHEL-family system, the equivalent install is `sudo dnf install -y openldap-servers openldap-clients` — but note that RHEL's package starts with an essentially empty configuration, while Debian/Ubuntu's `slapd` package runs an interactive `debconf` wizard on install that pre-seeds an organization name, a base DN guessed from the system's hostname, and an admin password. Either way, you should not assume the package's default values match the base DN your organization actually needs — treat Part III below as mandatory, not optional, regardless of distribution.)

Before changing anything, look at what the package install already produced:

```bash
sudo systemctl status slapd
sudo ss -tlnp | grep -E ':389|:636'
```

You should see `slapd` active, and port `389` already listening — that arrives automatically with the package. Port `636` (native LDAPS) will not be listening yet; enabling it is Part IV of this chapter.

---

## Part III: Claiming a Namespace and an Admin Identity

Every directory serves one or more **base DNs** (Distinguished Names) — the root of the tree it is authoritative for. For this module, that base DN is `dc=example,dc=com`, and the administrative identity permitted to write anything under it is `cn=admin,dc=example,dc=com`.

These values live on a specific entry inside `cn=config`: the database entry that backs your actual directory data, typically named `olcDatabase={1}mdb,cn=config` on a modern OpenLDAP install using the `mdb` backend. (The exact numeric index can differ; if in doubt, `sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcMdbConfig)" dn` will show you which entry it actually is on your system.)

Before writing a password anywhere, generate a salted hash for it — never a plaintext value:

```bash
slappasswd
# New password:
# Re-enter new password:
# {SSHA}gXK...redacted...
```

`slappasswd` prompts interactively and prints a hash (`{SSHA}` by default) suitable for direct use in an LDIF as `olcRootPW`. The plaintext password is typed once, into the prompt, and never written to disk, shell history, or a saved file. This matters practically: LDIF files get copied around, pasted into tickets, and occasionally committed to version control by accident. A plaintext `olcRootPW` sitting in one of those files is a permanent credential leak; a hash is not reversible in the same way.

With a hash in hand, apply the base DN, admin DN, and hashed password as a single modify operation:

```bash
cat > /tmp/set-suffix.ldif << 'EOF'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
-
replace: olcRootDN
olcRootDN: cn=admin,dc=example,dc=com
-
replace: olcRootPW
olcRootPW: {SSHA}gXK...redacted...
EOF

sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set-suffix.ldif
```

Notice the shape of this LDIF: a `dn:` naming exactly which config entry is being touched, a `changetype: modify`, and then one or more `replace:` attribute blocks separated by a line containing only a hyphen (`-`). This is the pattern you will reuse for every `cn=config` change in this module — only the target `dn:` and the attributes change.

`olcRootDN`/`olcRootPW` define an identity with unrestricted access to this one database, independent of any regular directory entry. It is the identity Module 2 will use to add users and groups, and the identity a client would use for an authenticated (rather than anonymous) bind.

---

## Part IV: Getting a Certificate the Daemon Can Actually Read

TLS needs a certificate and a private key. Generating one is not the focus of this module (see the dedicated OpenSSL material elsewhere in this course for the full mechanics of `openssl req`), but two details here are worth calling out because they are the most common way this exact setup breaks.

First, since every lab in this course runs as a single machine reachable at `127.0.0.1`, the certificate's Common Name (or Subject Alternative Name) should match the way clients will actually connect — `localhost` and `127.0.0.1` — rather than an external hostname nobody will ever dial:

```bash
sudo mkdir -p /etc/ldap/certs
sudo openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout /etc/ldap/certs/ldap-server.key \
  -out /etc/ldap/certs/ldap-server.crt \
  -days 3650 \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
```

Second — and this is the failure point worth memorizing — `slapd` does not run as root. It runs as a dedicated, unprivileged service account (`openldap` on Debian/Ubuntu, often `ldap` on RHEL-family systems; check with `ps -o user= -C slapd` if you are ever unsure). That account needs to be able to *read* the private key file, or TLS setup fails at daemon startup:

```bash
sudo chown openldap:openldap /etc/ldap/certs/ldap-server.key /etc/ldap/certs/ldap-server.crt
sudo chmod 640 /etc/ldap/certs/ldap-server.key
sudo chmod 644 /etc/ldap/certs/ldap-server.crt
```

A key that is world-readable is a security mistake. A key that is *too* restrictive — readable only by `root` when `slapd` runs as `openldap` — is an equally common mistake in the opposite direction, and it produces a startup failure that is easy to misdiagnose as a bad certificate rather than a filesystem permission problem.

---

## Part V: Wiring the Certificate into cn=config

With a readable certificate and key in place, point the top-level `cn=config` entry at them. TLS is a property of the daemon itself — not of any one database — so this modify targets `cn=config` directly, not the `olcDatabase={1}mdb` entry from Part III:

```bash
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

For a self-signed certificate, `olcTLSCACertificateFile` simply points back at the certificate itself — it is its own trust anchor. A restart is required here because, unlike most `cn=config` changes, TLS listener setup happens at daemon startup, not purely at runtime.

---

## Part VI: StartTLS on 389, or Native LDAPS on 636 — Why Both

OpenLDAP can offer encryption two different ways, and understanding the distinction matters for troubleshooting later, not just for passing this module.

**Native LDAPS**, on port 636, wraps the entire connection in TLS from the very first byte — exactly like HTTPS. The client knows before it speaks a word of the LDAP protocol that the channel is encrypted.

**StartTLS**, on the standard port 389, begins as a plain, unencrypted connection and then explicitly upgrades in place, mid-conversation, via an LDAP extended operation. This is what most modern tooling (`ldapsearch -Z`/`-ZZ`, `sssd`) defaults to, because it lets one port serve both TLS-aware clients and, if the server allows it, older plaintext ones — no second listening port required in principle.

A production directory commonly offers both anyway, for compatibility with whatever mix of client software actually exists in an environment. To enable the LDAPS listener, add `ldaps:///` to `slapd`'s list of listening URLs. On Debian/Ubuntu this list lives in `/etc/default/slapd`, in the `SLAPD_SERVICES` variable:

```bash
sudo vi /etc/default/slapd
```

```
SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"
```

```bash
sudo systemctl restart slapd
```

Three listeners, three purposes: `ldap:///` is the plain/StartTLS-capable port 389, `ldaps:///` is native TLS on 636, and `ldapi:///` is the local UNIX socket used throughout this module for `cn=config` administration.

---

## Part VII: Proving It, Not Assuming It

A configuration that "should" work is not the same as a configuration that does. Verify at two separate layers, because they can fail independently of each other.

First, the transport layer — does a raw TLS handshake even complete?

```bash
openssl s_client -connect 127.0.0.1:636 -showcerts </dev/null
```

A full certificate chain and a `Verify return code:` line at the end mean the handshake worked. `18 (self-signed certificate)` is an *expected* and acceptable result here — it tells you the certificate isn't signed by a public CA, which is fine for a self-signed lab cert; it does not mean the handshake failed.

Second, the LDAP application layer — does StartTLS actually negotiate through `slapd` itself?

```bash
ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base
```

`-ZZ` requires StartTLS to succeed before the search proceeds at all, and aborts with an explicit error if it doesn't — so any search result returned here is real proof the encrypted upgrade actually worked end to end, not just that port 636 happens to be open. If `openssl s_client` succeeds but this command fails, you have just isolated the problem: the network/TLS layer is fine, and the fault is in how `cn=config`'s TLS attributes are wired to the LDAP-level StartTLS operation, or in client-side trust configuration — not in the certificate or key files themselves.

At this point, `slapd` is installed, serving `dc=example,dc=com`, administered by `cn=admin,dc=example,dc=com`, and reachable over both StartTLS and native LDAPS with a verified handshake. It is also completely empty. That is exactly where Module 2 picks up.

---

## Self-Check and Verification

Test your understanding before moving forward:
1.  **Configuration Model**: Why can't you just `vi /etc/ldap/slapd.conf` on a modern OpenLDAP install, and what tool/flags do you use instead to change `cn=config`?
2.  **Protocol Distinction**: What is actually different, mechanically, between StartTLS on 389 and native LDAPS on 636? *(Answer: StartTLS begins in plaintext on the standard port and upgrades in place via an LDAP extended operation; native LDAPS encrypts the entire connection from the first byte on its own dedicated port, like HTTPS.)*
3.  **Isolating a Failure**: If `openssl s_client -connect 127.0.0.1:636` completes a handshake but `ldapsearch -x -ZZ -H ldap://127.0.0.1` still fails, which layer of the stack is *not* the problem, and why? *(Answer: The network/TLS transport layer is not the problem — it already proved it works. The fault is at the LDAP application layer: how `cn=config`'s TLS attributes are wired to the StartTLS operation, or a client-side trust issue.)*
