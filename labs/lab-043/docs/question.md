# Question

Solve this question on: `terminal`

This host is already running a TLS-secured, populated OpenLDAP server on `127.0.0.1` (base DN `dc=example,dc=com`), containing a `developers` group (GID `5000`) and a user `uid=lfcsuser,ou=people,dc=example,dc=com` (UID `10001`, home `/home/lfcsuser`, shell `/bin/bash`). The `sssd`, `sssd-ldap`, `libnss-sss`, and `libpam-sss` packages are already installed. The server's TLS certificate is available locally at `/etc/ldap/certs/ldap-server.crt`.

Configure this host to authenticate against that directory using `sssd`:

1.  Write `/etc/sssd/sssd.conf` with a domain pointing at `ldap://127.0.0.1`, base DN `dc=example,dc=com`, using StartTLS, and trusting the server's certificate.
2.  Set `/etc/sssd/sssd.conf` to mode `600`, owned `root:root`.
3.  Add `sss` to the `passwd` and `group` lines in `/etc/nsswitch.conf`.
4.  Start (and enable) `sssd`.
5.  Verify, **in this order**: that `getent passwd lfcsuser` and `getent group developers` resolve correctly, that `id lfcsuser` shows the right UID and group, and that `getent passwd root` / `id root` still work exactly as before.

## Verify authentication as well as identity

`getent` proves an identity lookup; it does not test a password. This lab also provides a PAM service named `lfcs-ldap` that uses `pam_sss`. Run:

```sh
pamtester lfcs-ldap lfcsuser authenticate
```

Enter the training password `LfcsLdap!2024`, then repeat with a wrong password. The first attempt should succeed and the second should fail. Do not use root's `su` as a password test: root can switch users without authenticating as that user.

Set `ldap_tls_reqcert = demand` in the SSSD domain configuration. Trust the lab certificate with `ldap_tls_cacert`; disabling certificate verification is not a repair. After changing the configuration, restart SSSD.

The grader creates a temporary directory identity, resolves it through SSSD, checks its correct and incorrect passwords, then removes it. This proves a fresh lookup rather than relying on a cached account or a matching local user. CI also replaces the trust certificate with an unrelated certificate and requires a fresh lookup to fail.
