#!/usr/bin/env bash
# Fully provisions lab-041's end state: installs slapd, generates a
# self-signed TLS cert/key, sets base DN dc=example,dc=com with admin
# cn=admin,dc=example,dc=com / LdapRoot!2024, wires TLS into cn=config, and
# enables both StartTLS (389) and native LDAPS (636). The directory itself
# is left empty - populating it is this lab's graded task.
set -eu

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y slapd ldap-utils openssl

BASE_DN="dc=example,dc=com"
ADMIN_DN="cn=admin,dc=example,dc=com"
ADMIN_PASSWORD="LdapRoot!2024"

mkdir -p /etc/ldap/certs
if [[ ! -f /etc/ldap/certs/ldap-server.key ]]; then
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout /etc/ldap/certs/ldap-server.key \
    -out /etc/ldap/certs/ldap-server.crt \
    -days 3650 \
    -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
fi

chown openldap:openldap /etc/ldap/certs/ldap-server.key /etc/ldap/certs/ldap-server.crt
chmod 640 /etc/ldap/certs/ldap-server.key
chmod 644 /etc/ldap/certs/ldap-server.crt

ADMIN_HASH=$(slappasswd -s "$ADMIN_PASSWORD")

cat > /tmp/set-suffix.ldif << EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: ${BASE_DN}
-
replace: olcRootDN
olcRootDN: ${ADMIN_DN}
-
replace: olcRootPW
olcRootPW: ${ADMIN_HASH}
EOF
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set-suffix.ldif

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
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set-tls.ldif

if grep -q '^SLAPD_SERVICES=' /etc/default/slapd; then
  sed -i 's|^SLAPD_SERVICES=.*|SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"|' /etc/default/slapd
else
  echo 'SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"' >> /etc/default/slapd
fi

systemctl restart slapd
sleep 2

rm -f /tmp/set-suffix.ldif /tmp/set-tls.ldif

echo "Bootstrap complete: TLS-enabled OpenLDAP server ready at dc=example,dc=com, empty (lab-041 end state)."
exit 0
