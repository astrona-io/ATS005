# Solution Walkthrough

Follow these steps on the terminal to populate the directory and prove the TLS bind works.

---

## Step 1: Write and apply the organizational-unit LDIF

```bash
cat > /tmp/ou-structure.ldif << 'EOF'
dn: ou=people,dc=example,dc=com
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=example,dc=com
objectClass: organizationalUnit
ou: groups
EOF

ldapadd -x -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 -f /tmp/ou-structure.ldif
```

---

## Step 2: Write and apply the group and user LDIF

```bash
cat > /tmp/lfcsuser.ldif << 'EOF'
dn: cn=developers,ou=groups,dc=example,dc=com
objectClass: posixGroup
cn: developers
gidNumber: 5000

dn: uid=lfcsuser,ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: LFCS User
sn: User
uid: lfcsuser
uidNumber: 10001
gidNumber: 5000
homeDirectory: /home/lfcsuser
loginShell: /bin/bash
EOF

ldapadd -x -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 -f /tmp/lfcsuser.ldif
```

The parent `ou=people` entry from Step 1 must exist before this add succeeds — LDAP does not create intermediate containers implicitly.

---

## Step 3: Set the user's password

```bash
ldappasswd -x -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 \
  -s "LfcsLdap!2024" \
  "uid=lfcsuser,ou=people,dc=example,dc=com"
```

(`-s` supplies the new password non-interactively here; interactively you would use `-S` and be prompted instead.)

---

## Step 4: Search for the new entries

```bash
ldapsearch -x -ZZ -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 \
  -b "dc=example,dc=com" "(uid=lfcsuser)"

ldapsearch -x -ZZ -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 \
  -b "dc=example,dc=com" "(cn=developers)"
```

Both should return their full entries, including `uidNumber: 10001`, `gidNumber: 5000`, `homeDirectory: /home/lfcsuser`, `loginShell: /bin/bash` for the user, and `gidNumber: 5000` for the group.

---

## Step 5: Prove the authenticated bind works over TLS

```bash
ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -w "LfcsLdap!2024" -ZZ -H ldap://127.0.0.1
```

Expect the bind DN echoed back, proving three things at once: the entry exists, the password is correct, and the exchange happened over an encrypted, StartTLS-upgraded connection.

Try the same bind without `-ZZ` to see the difference:

```bash
ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -w "LfcsLdap!2024" -H ldap://127.0.0.1
```

This either succeeds insecurely (password sent in the clear) or is rejected outright, depending on whether the server enforces TLS for simple binds — either way, it demonstrates why `-ZZ` is the version that actually matters.

Once all of the above pass, run the local validation suite to pass the lab!
