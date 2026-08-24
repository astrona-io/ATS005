# Question

Solve this question on: `terminal`

The host `data-001` has `slapd` and `ldap-utils` already installed, and a self-signed TLS certificate/key pair already generated at `/etc/ldap/certs/ldap-server.crt` and `/etc/ldap/certs/ldap-server.key` (owned by the `openldap` user). Your organization needs this server to become a real, TLS-secured directory:

1.  Configure the server, via `cn=config`, to serve base DN **`dc=example,dc=com`** with an admin bind DN of **`cn=admin,dc=example,dc=com`** and an admin password of **`LdapRoot!2024`**. Set the password as a hash (via `slappasswd`), never as plaintext.
2.  Wire the pre-supplied certificate and key at `/etc/ldap/certs/ldap-server.crt` / `/etc/ldap/certs/ldap-server.key` into `cn=config`'s TLS attributes.
3.  Ensure `slapd` listens on **both** port 389 (for StartTLS) and port 636 (native LDAPS), and restart it so the changes take effect.
4.  Confirm a TLS handshake actually succeeds against port 636, and that a StartTLS-required `ldapsearch` against port 389 also succeeds.

Leave the directory otherwise empty — no organizational units, groups, or user entries. Populating it is a separate task.
