# Solution Walkthrough

Follow these steps on the terminal to complete the full server-to-client identity loop.

---

## Part 1: Server & TLS

### Step 1: Generate the admin password hash

```bash
slappasswd
# New password: LdapRoot!2024
# Re-enter new password: LdapRoot!2024
# {SSHA}gXK...redacted...
```

### Step 2: Set the base DN and admin credentials

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

### Step 3: Wire the pre-supplied certificate/key into cn=config

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

### Step 4: Enable both listeners

```bash
sudo vi /etc/default/slapd
# SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"

sudo systemctl restart slapd
```

### Step 5: Verify

```bash
sudo ss -tlnp | grep -E ':389|:636'
openssl s_client -connect 127.0.0.1:636 -brief </dev/null
ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base
ldapwhoami -x -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -ZZ -H ldap://127.0.0.1
```

---

## Part 2: Directory Population

### Step 6: Organizational units, group, and user

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

### Step 7: Set lfcsuser's password

```bash
ldappasswd -x -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 \
  -s "LfcsLdap!2024" \
  "uid=lfcsuser,ou=people,dc=example,dc=com"
```

### Step 8: Verify

```bash
ldapsearch -x -ZZ -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 \
  -b "dc=example,dc=com" "(uid=lfcsuser)"
ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -w "LfcsLdap!2024" -ZZ -H ldap://127.0.0.1
```

---

## Part 3: SSSD Client Integration

### Step 9: Write sssd.conf

```bash
sudo vi /etc/sssd/sssd.conf
```

```ini
[sssd]
config_file_version = 2
services = nss, pam
domains = example.com

[domain/example.com]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://127.0.0.1
ldap_search_base = dc=example,dc=com
ldap_id_use_start_tls = true
ldap_tls_cacert = /etc/ldap/certs/ldap-server.crt
cache_credentials = True
```

### Step 10: Lock down permissions and wire nsswitch.conf

```bash
sudo chown root:root /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf

sudo vi /etc/nsswitch.conf
# passwd: files sss
# group:  files sss
```

### Step 11: Start sssd and verify in order

```bash
sudo systemctl enable --now sssd
sudo systemctl status sssd

getent passwd lfcsuser
getent group developers
id lfcsuser

getent passwd root
id root
```

Expect `lfcsuser` and `developers` to resolve with the correct UID/GID/home/shell, and `root` to resolve exactly as it always has, proving the LDAP/sssd integration is additive rather than disruptive.

Once all three parts pass, run the local validation suite to pass the lab!
