# Solution Walkthrough

Follow these steps on the terminal to configure the base DN, wire up TLS, and enable both listeners.

---

## Step 1: Confirm what's already there

```bash
sudo systemctl status slapd
sudo ss -tlnp | grep -E ':389|:636'
ls -l /etc/ldap/certs/
```

`slapd` should already be active with port 389 listening (from the package install), and the pre-generated certificate/key should already exist under `/etc/ldap/certs/`, owned by `openldap`. Port 636 is not listening yet.

---

## Step 2: Generate a password hash for the admin identity

```bash
slappasswd
# New password: LdapRoot!2024
# Re-enter new password: LdapRoot!2024
# {SSHA}gXK...redacted...
```

Copy the printed hash — you will use it in the next step. Never write the plaintext password into an LDIF file.

---

## Step 3: Set the base DN and admin credentials via cn=config

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

If the exact database index differs from `{1}`, find it first:

```bash
sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcMdbConfig)" dn
```

---

## Step 4: Point cn=config at the pre-supplied certificate and key

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

---

## Step 5: Enable the LDAPS listener on 636

```bash
sudo vi /etc/default/slapd
```

Set:

```
SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"
```

```bash
sudo systemctl restart slapd
```

---

## Step 6: Verify

```bash
sudo ss -tlnp | grep -E ':389|:636'
```

Both ports should show `LISTEN` owned by `slapd`.

```bash
openssl s_client -connect 127.0.0.1:636 -brief </dev/null
```

Expect a completed handshake. `Verify return code: 18 (self-signed certificate)` is expected and fine.

```bash
ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base
```

Expect clean root DSE output — this proves StartTLS negotiated successfully, not merely that port 389 is open.

```bash
ldapwhoami -x -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -ZZ -H ldap://127.0.0.1
```

Expect the admin's own DN echoed back, proving the admin bind and its password both work over an encrypted connection.

Once all of the above pass, run the local validation suite to pass the lab!
