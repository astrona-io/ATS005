#!/usr/bin/env bash
set -euo pipefail
hash=$(sudo slappasswd -s 'LdapRoot!2024')
sudo tee /tmp/suffix.ldif >/dev/null <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
-
replace: olcRootDN
olcRootDN: cn=admin,dc=example,dc=com
-
replace: olcRootPW
olcRootPW: $hash
EOF
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/suffix.ldif
sudo tee /tmp/tls.ldif >/dev/null <<'REFERENCE_FILE'
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
REFERENCE_FILE
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/tls.ldif
sudo sed -i 's|^SLAPD_SERVICES=.*|SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"|' /etc/default/slapd
sudo systemctl restart slapd
sudo tee /etc/ldap/ldap.conf >/dev/null <<'REFERENCE_FILE'
TLS_CACERT /etc/ldap/certs/ldap-server.crt
TLS_REQCERT demand
REFERENCE_FILE
