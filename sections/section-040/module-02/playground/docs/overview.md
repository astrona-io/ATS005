# Overview: PLAYGROUND — LDAP Directory Population & TLS Bind Verification

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh astro-ldap-populate-playground`.
- Module 1's finished state, provisioned automatically: a TLS-secured OpenLDAP
  server serving **`dc=example,dc=com`**, admin bind DN
  **`cn=admin,dc=example,dc=com`**, admin password **`LdapRoot!2024`**,
  listening on `389` (StartTLS) and `636` (LDAPS).
- The server's certificate at `/etc/ldap/certs/ldap-server.crt`.
- The directory is **empty** — no `ou=`, no groups, no users.

## Things to try

- `ldapadd -x -W -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f <ldif>`
  to add `ou=people` and `ou=groups`, then a `posixGroup` and a
  `posixAccount` + `inetOrgPerson` user.
- Deliberately omit the blank line between two LDIF entries and watch `ldapadd`
  reject the file.
- Set a password with `ldappasswd -x -W -D "cn=admin,dc=example,dc=com" -S <userdn>`.
- Compare `ldapsearch -x` (anonymous), `ldapsearch -x -ZZ` (StartTLS required),
  and `ldapwhoami -x -D <userdn> -W -ZZ` (bind as the user over TLS).
- Try `ldapwhoami` with `-Z` vs `-ZZ` vs neither and see how the outcomes
  differ.

## When you're done

```sh
astrona destroy astro-ldap-populate-playground
```
