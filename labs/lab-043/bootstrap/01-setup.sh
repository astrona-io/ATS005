#!/usr/bin/env bash
# Fully provisions lab-041+lab-042's end state: a TLS-enabled, populated
# OpenLDAP server at dc=example,dc=com (developers group + lfcsuser
# account), and additionally installs sssd and its NSS/PAM support
# packages. Writing /etc/sssd/sssd.conf and wiring nsswitch.conf are left
# as this lab's graded task.
set -eu

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y slapd ldap-utils openssl sssd sssd-ldap libnss-sss libpam-sss

BASE_DN="dc=example,dc=com"
ADMIN_DN="cn=admin,dc=example,dc=com"
ADMIN_PASSWORD="LdapRoot!2024"
LFCS_PASSWORD="LfcsLdap!2024"

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

LFCS_HASH=$(slappasswd -s "$LFCS_PASSWORD")

cat > /tmp/populate.ldif << EOF
dn: ou=people,${BASE_DN}
objectClass: organizationalUnit
ou: people

dn: ou=groups,${BASE_DN}
objectClass: organizationalUnit
ou: groups

dn: cn=developers,ou=groups,${BASE_DN}
objectClass: posixGroup
cn: developers
gidNumber: 5000

dn: uid=lfcsuser,ou=people,${BASE_DN}
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
userPassword: ${LFCS_HASH}
EOF
ldapadd -x -D "${ADMIN_DN}" -w "${ADMIN_PASSWORD}" -H ldap://127.0.0.1 -f /tmp/populate.ldif

rm -f /tmp/set-suffix.ldif /tmp/set-tls.ldif /tmp/populate.ldif

echo "Bootstrap complete: TLS-enabled, populated OpenLDAP server ready; sssd + NSS/PAM modules installed. Configure /etc/sssd/sssd.conf and nsswitch.conf as your task."
exit 0
