# Question

Solve this question on: `terminal`

Your organization needs this host, `data-001`, to become both a centralized LDAP identity server and a client of that same server, proving the whole chain works end to end. The `slapd`, `ldap-utils`, `openssl`, `sssd`, `sssd-ldap`, `libnss-sss`, and `libpam-sss` packages are already installed, and a self-signed TLS certificate/key pair already exists at `/etc/ldap/certs/ldap-server.crt` / `/etc/ldap/certs/ldap-server.key` (owned by `openldap`). Nothing else has been configured. Complete the following:

### Part 1: Server & TLS

1.  Configure the server, via `cn=config`, to serve base DN **`dc=example,dc=com`** with admin bind DN **`cn=admin,dc=example,dc=com`** and admin password **`LdapRoot!2024`** (set as a hash, never plaintext).
2.  Wire the pre-supplied certificate/key into `cn=config`'s TLS attributes.
3.  Ensure `slapd` listens on both port 389 (StartTLS) and port 636 (native LDAPS), and restart it.

### Part 2: Directory Population

4.  Create `ou=people` and `ou=groups` under `dc=example,dc=com`.
5.  Add a POSIX group `cn=developers,ou=groups,dc=example,dc=com`, GID `5000`.
6.  Add a full POSIX user `uid=lfcsuser,ou=people,dc=example,dc=com` — UID `10001`, primary group `5000`, home `/home/lfcsuser`, shell `/bin/bash`.
7.  Set `lfcsuser`'s password to exactly **`LfcsLdap!2024`**.

### Part 3: SSSD Client Integration

8.  Write `/etc/sssd/sssd.conf` so this host authenticates against its own LDAP server on `127.0.0.1`, using StartTLS and trusting the server's certificate (`/etc/ldap/certs/ldap-server.crt`), with search base `dc=example,dc=com`.
9.  Set `/etc/sssd/sssd.conf` to mode `600`, owned `root:root`.
10. Add `sss` to the `passwd` and `group` lines in `/etc/nsswitch.conf`, then start and enable `sssd`.
11. Verify, **in order**: `getent passwd lfcsuser` / `getent group developers` resolve correctly, `id lfcsuser` resolves with the right UID and group, and — critically — `getent passwd root` / `id root` still work exactly as before, completely unaffected by everything above.
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-01](../../../sections/section-040/module-01/course.md), [module-02](../../../sections/section-040/module-02/course.md), [module-03](../../../sections/section-040/module-03/course.md), [module-04](../../../sections/section-040/module-04/course.md).

The grader checks:

- Confirms slapd serves dc=example,dc=com, listens on 389 and 636, negotiates TLS on both, and accepts the admin bind with the expected rootPW.
- Confirms ou=people/ou=groups, the developers posixGroup (gid 5000), and the lfcsuser posixAccount (uid 10001) exist with correct attributes and lfcsuser's bind works over StartTLS.
- Confirms sssd.conf/nsswitch.conf are correctly wired and lfcsuser/developers resolve via NSS.
- Confirms local accounts (root) still resolve and authenticate exactly as before the LDAP/sssd integration.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
