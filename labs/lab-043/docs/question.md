# Question

Solve this question on: `terminal`

This host is already running a TLS-secured, populated OpenLDAP server on `127.0.0.1` (base DN `dc=example,dc=com`), containing a `developers` group (GID `5000`) and a user `uid=lfcsuser,ou=people,dc=example,dc=com` (UID `10001`, home `/home/lfcsuser`, shell `/bin/bash`). The `sssd`, `sssd-ldap`, `libnss-sss`, and `libpam-sss` packages are already installed. The server's TLS certificate is available locally at `/etc/ldap/certs/ldap-server.crt`.

Configure this host to authenticate against that directory using `sssd`:

1.  Write `/etc/sssd/sssd.conf` with a domain pointing at `ldap://127.0.0.1`, base DN `dc=example,dc=com`, using StartTLS, and trusting the server's certificate.
2.  Set `/etc/sssd/sssd.conf` to mode `600`, owned `root:root`.
3.  Add `sss` to the `passwd` and `group` lines in `/etc/nsswitch.conf`.
4.  Start (and enable) `sssd`.
5.  Verify, **in this order**: that `getent passwd lfcsuser` and `getent group developers` resolve correctly, that `id lfcsuser` shows the right UID and group, and that `getent passwd root` / `id root` still work exactly as before.
