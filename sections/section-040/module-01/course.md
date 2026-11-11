# LDAP Server Installation & TLS

Astronaut, before any ship in the fleet can look up a crew member in one shared roster, that roster has to exist. LDAP (Lightweight Directory Access Protocol) is the language ships use to ask a **fleet registry**: one shared crew roster that many ships consult. On Linux, the OpenLDAP server program `slapd` runs that registry.

This module takes a `slapd` that is running but not set up, and turns it into a registry that serves `dc=example,dc=com`, has an administrator, and seals every conversation with TLS (Transport Layer Security, the encryption that keeps a password from crossing the network in the clear). The registry stays empty: filling it is a separate job.

## Learning objectives

After this module you can:

- Explain why modern OpenLDAP has no `slapd.conf`, and change `cn=config` with `ldapmodify` over `ldapi:///` and SASL EXTERNAL.
- Set a server's base DN, administrator bind DN and hashed administrator password on the `mdb` database entry.
- Make a password hash with `slappasswd`, and explain why a plaintext `olcRootPW` is a credential leak.
- Make a TLS key readable by the `openldap` service account and wire the certificate into `cn=config`.
- Tell StartTLS on port 389 from native LDAPS on port 636, and switch on the 636 listener.
- Prove TLS at the transport layer with `openssl s_client` and at the LDAP layer with `ldapsearch -ZZ`.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **Services and sockets.** `systemctl`, editing files under `/etc`, and reading `ss` output.
- **TLS basics.** TLS needs a certificate plus a private key, and a "handshake" is the short exchange that sets up the encrypted channel.
- **Two names used everywhere.** A **DN** (distinguished name) is the full, path-like address of one entry in the registry, read from right to left: `cn=admin,dc=example,dc=com` sits under `dc=example,dc=com`. **DC** means "domain component": `dc=example,dc=com` is the name `example.com` written as the top shelf of the registry.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- `slapd` (the OpenLDAP server) and `ldap-utils` installed, with `slapd` running on port `389` and only the package defaults.
- A self-signed certificate and key at `/etc/ldap/certs/ldap-server.crt` and `/etc/ldap/certs/ldap-server.key`, owned by the `openldap` service account, with `CN=localhost` and the extra names (SANs) `localhost` and `127.0.0.1`.
- Port `636` **not** listening yet.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh ldap-server-tls-playground
```

Every command block in the parts runs **inside that virtual machine**.

## How this module is laid out

1. [The Configuration Is A Tree](./course-01-the-configuration-is-a-tree.md): `cn=config`, the `ldap*` tool family, and how to read the running configuration.
2. [Naming The Directory And Its Administrator](./course-02-naming-the-directory.md): `olcSuffix`, `olcRootDN` and a hashed `olcRootPW`.
3. [Giving The Server Its Certificate](./course-03-giving-the-server-its-certificate.md): key permissions for `openldap`, and the TLS attributes in `cn=config`.
4. [Opening Port 636 And Proving TLS](./course-04-opening-port-636-and-proving-tls.md): StartTLS versus LDAPS, `SLAPD_SERVICES`, and proof at two layers.
   - Mission: [OpenLDAP Server Install & TLS Lab](../../../labs/lab-041/docs/question.md)
5. [Wrap-Up: Mission Debrief](./course-05-wrap-up.md)

## Why this matters

Every host that will later look up users in this registry depends on the name, the administrator and the encrypted endpoint you set up here. If TLS is wrong, every bind password crosses the network in plain text, or every client refuses to connect.

The certificate itself is taken as given in this module. The job is wiring it into the server and proving that it negotiates.

> *`slapd` running is not the same as TLS working: the registry is ready only once an encrypted handshake is proven, not merely configured.*

<!-- curriculum-practice -->
## Practice and assessment

- [OpenLDAP Server Install & TLS Lab](../../../labs/lab-041/docs/question.md): Set the base DN, admin DN and hashed admin password through cn=config; Wire a certificate and key into slapd and listen on ports 389 and 636; Prove that StartTLS and LDAPS both work.
- [Centralized Identity with LDAP Capstone Lab](../../../labs/lab-040/docs/question.md): Build a TLS-secured OpenLDAP server and populate it with a POSIX group and user; Wire the same host into the directory with sssd and nsswitch; Prove that directory users resolve while local accounts stay unaffected.

## Trust the lab certificate before testing TLS

The server settings do not configure client trust. Install the lab certificate as the client trust anchor and require certificate verification:

```bash
sudo tee /etc/ldap/ldap.conf >/dev/null <<'EOF'
TLS_CACERT /etc/ldap/certs/ldap-server.crt
TLS_REQCERT demand
EOF
openssl s_client -connect 127.0.0.1:636 \
  -CAfile /etc/ldap/certs/ldap-server.crt -verify_ip 127.0.0.1 \
  -verify_return_error -brief </dev/null
```

A successful handshake alone does not prove trust. This command must verify the certificate and the address. Then test StartTLS with `ldapsearch -ZZ`; keep verification enabled.
