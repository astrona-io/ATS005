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
sudo tee /tmp/directory.ldif >/dev/null <<'REFERENCE_FILE'
dn: dc=example,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: Example Training
dc: example

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
REFERENCE_FILE
ldapadd -x -ZZ -D cn=admin,dc=example,dc=com -w 'LdapRoot!2024' -H ldap://127.0.0.1 -f /tmp/directory.ldif
ldappasswd -x -ZZ -D cn=admin,dc=example,dc=com -w 'LdapRoot!2024' -H ldap://127.0.0.1 -s 'LfcsLdap!2024' uid=lfcsuser,ou=people,dc=example,dc=com
sudo mkdir -p /etc/sssd
sudo tee /etc/sssd/sssd.conf >/dev/null <<'EOF'
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
ldap_tls_reqcert = demand
ldap_tls_cacert = /etc/ldap/certs/ldap-server.crt
cache_credentials = True
EOF
sudo chown root:root /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf
sudo sed -i -E 's/^passwd:.*/passwd: files sss/; s/^group:.*/group: files sss/' /etc/nsswitch.conf
sudo systemctl enable sssd
sudo systemctl restart sssd
for attempt in $(seq 1 20); do
  if getent -s sss passwd lfcsuser; then break; fi
  sleep 2
done
getent -s sss passwd lfcsuser
