#!/usr/bin/env bash
# OS prep for PLAYGROUND — LDAP Directory Population & TLS Bind Verification
# Runs once when the environment comes up. Reproduces Module 1's finished state:
# a TLS-secured OpenLDAP server serving dc=example,dc=com, admin
# cn=admin,dc=example,dc=com / LdapRoot!2024, listening on 389 (StartTLS) and
# 636 (LDAPS). The directory itself is left EMPTY — populating it is what the
# reader does. Nothing to solve, no grading.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "[playground] ldap-populate: installing + configuring a TLS LDAP server..."
apt-get update -qq
apt-get install -y -qq slapd ldap-utils openssl >/dev/null

# --- self-signed cert/key readable by the openldap account ---------------
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

# --- base DN + admin identity on the mdb database entry -----------------
HASH=$(slappasswd -s 'LdapRoot!2024')
cat > /tmp/pg-suffix.ldif <<EOF
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
EOF
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/pg-suffix.ldif

# --- TLS attributes on cn=config --------------------------------------------
cat > /tmp/pg-tls.ldif <<'EOF'
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
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/pg-tls.ldif

# --- enable the 636 listener ----------------------------------------------
sed -i 's|^SLAPD_SERVICES=.*|SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"|' /etc/default/slapd
systemctl restart slapd

rm -f /tmp/pg-suffix.ldif /tmp/pg-tls.ldif
echo "[playground] ready. TLS LDAP server for dc=example,dc=com is up and EMPTY."
echo "  Try:  ldapsearch -x -ZZ -H ldap://127.0.0.1 -b dc=example,dc=com -LLL"
