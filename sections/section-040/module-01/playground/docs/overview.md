# Overview: PLAYGROUND — LDAP Server Installation & TLS

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh astro-ldap-server-tls-playground`.
- `slapd` (the OpenLDAP daemon) and `ldap-utils` installed; `slapd` running on
  port `389` with only the package-default configuration.
- A self-signed TLS certificate and key at `/etc/ldap/certs/ldap-server.crt`
  and `/etc/ldap/certs/ldap-server.key`, owned by the `openldap` service
  account, `CN=localhost` with SANs for `localhost` and `127.0.0.1`.
- Port `636` is **not** listening yet — you enable it.

## Things to try

- `sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config -LLL dn` — list the
  live `cn=config` tree.
- Generate a hash with `slappasswd`, then set `olcSuffix`, `olcRootDN`, and
  `olcRootPW` on `olcDatabase={1}mdb,cn=config` to serve `dc=example,dc=com`.
- Point `olcTLSCertificateFile` / `olcTLSCertificateKeyFile` /
  `olcTLSCACertificateFile` at the pre-made cert, restart `slapd`.
- Add `ldaps:///` to `SLAPD_SERVICES` in `/etc/default/slapd`, restart, and
  check `sudo ss -tlnp | grep -E ':389|:636'`.
- `openssl s_client -connect 127.0.0.1:636 </dev/null` and
  `ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base` to verify both layers.

## When you're done

```sh
astrona destroy astro-ldap-server-tls-playground
```
