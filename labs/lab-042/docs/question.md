# Question

Solve this question on: `terminal`

The host `data-001` is already running a TLS-secured OpenLDAP server at base DN `dc=example,dc=com`, with admin bind DN `cn=admin,dc=example,dc=com` and admin password `LdapRoot!2024` (the completed end state of the previous lab). The directory itself is empty. Populate it:

1.  Create organizational units `ou=people` and `ou=groups` directly under `dc=example,dc=com`.
2.  Add a POSIX group `cn=developers,ou=groups,dc=example,dc=com` with GID `5000`.
3.  Add a full POSIX user `uid=lfcsuser,ou=people,dc=example,dc=com` — UID `10001`, primary group `5000`, home directory `/home/lfcsuser`, shell `/bin/bash`.
4.  Set `lfcsuser`'s password to exactly **`LfcsLdap!2024`**.
5.  Prove, using `ldapsearch`, that the new entries are searchable.
6.  Prove, using `ldapwhoami`, that an authenticated bind as `lfcsuser` with the password above succeeds when StartTLS is **required** (`-ZZ`) against `ldap://127.0.0.1`.
