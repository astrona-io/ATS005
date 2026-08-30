#!/usr/bin/env bash
# OS prep for PLAYGROUND — LDAP Client Integration with SSSD
# Runs once when the environment comes up. Reproduces Modules 1-2's finished
# state: a TLS-secured OpenLDAP server for dc=example,dc=com, populated with
# ou=people / ou=groups, a `developers` posixGroup (GID 5000) and a `lfcsuser`
# posixAccount (UID 10001, password LfcsLdap!2024). The sssd packages are
# installed but NOT configured — no sssd.conf, nsswitch.conf untouched, sssd
# not running. Wiring the client is what the reader does. Nothing to solve.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "[playground] sssd-client: standing up a populated TLS LDAP server..."
apt-get update -qq
apt-get install -y -qq slapd ldap-utils openssl sssd sssd-ldap libnss-sss libpam-sss sshpass >/dev/null

# --- cert/key ------------------------------------------------------------
install -d -m 755 /etc/ldap/certs
if [ ! -f /etc/ldap/certs/ldap-server.crt ]; then
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout /etc/ldap/certs/ldap-server.key \
        -out    /etc/ldap/certs/ldap-server.crt \
        -days 3650 -subj "/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" 2>/dev/null
fi
chown openldap:openldap /etc/ldap/certs/ldap-server.key /etc/ldap/certs/ldap-server.crt
chmod 640 /etc/ldap/certs/ldap-server.key
chmod 644 /etc/ldap/certs/ldap-server.crt

# --- base DN + admin + TLS on cn=config --------------------------------
HASH=$(slappasswd -s 'LdapRoot!2024')
cat > /tmp/pg-cfg.ldif <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
-
replace: olcRootDN
olcRootDN: cn=admin,dc=example,dc=com
-
replace: olcRootPW
olcRootPW: ${HASH}

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
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/pg-cfg.ldif
sed -i 's|^SLAPD_SERVICES=.*|SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"|' /etc/default/slapd
systemctl restart slapd
sleep 2

# --- populate the directory (Module 2's output) -----------------------
cat > /tmp/pg-data.ldif <<'EOF'
dn: ou=people,dc=example,dc=com
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=example,dc=com
objectClass: organizationalUnit
ou: groups

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
ldapadd -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f /tmp/pg-data.ldif
ldappasswd -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 \
    -s 'LfcsLdap!2024' "uid=lfcsuser,ou=people,dc=example,dc=com"

# --- client side: packages present, config ABSENT -------------------
# create home dirs for LDAP users on first login, so the login test is clean
pam-auth-update --enable mkhomedir >/dev/null 2>&1 || true
systemctl stop sssd 2>/dev/null || true
systemctl disable sssd 2>/dev/null || true
rm -f /etc/sssd/sssd.conf

rm -f /tmp/pg-cfg.ldif /tmp/pg-data.ldif
echo "[playground] ready. Populated TLS LDAP server up; sssd installed but UNCONFIGURED."
echo "  Try:  getent passwd lfcsuser   (nothing yet — no sssd.conf, no 'sss' in nsswitch)"
