#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Starting state for lab-044: a populated TLS LDAP server, a wired sssd client,
# users lfcsuser and newcomer, no home folders and pam_mkhomedir off.
# Enabling mkhomedir and the starter file are the graded task.
sudo -n bash <<'BOOTSTRAP_ROOT'
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


# --- second directory user, and a wired sssd client ------------------
NEWCOMER_HASH=$(slappasswd -s 'LfcsLdap!2024')
cat > /tmp/newcomer.ldif <<LDIF
dn: uid=newcomer,ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: New Comer
sn: Comer
uid: newcomer
uidNumber: 10002
gidNumber: 5000
homeDirectory: /home/newcomer
loginShell: /bin/bash
userPassword: ${NEWCOMER_HASH}
LDIF
ldapadd -x -D "${ADMIN_DN}" -w "$ADMIN_PASSWORD" -H ldap://127.0.0.1 -f /tmp/newcomer.ldif
rm -f /tmp/newcomer.ldif

install -d -m 755 /etc/sssd
cat > /etc/sssd/sssd.conf <<'SSSD'
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
SSSD
chown root:root /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf
sed -i -E '/^(passwd|group):/ { /sss/! s/$/ sss/ }' /etc/nsswitch.conf
systemctl enable --now sssd
sleep 3

rm -f /tmp/set-suffix.ldif /tmp/set-tls.ldif /tmp/populate.ldif

# mkhomedir is off: enabling it is the task.
sed -i '/pam_mkhomedir/d' /etc/pam.d/common-session

echo "Bootstrap complete: sssd wired, users resolve, no mkhomedir."
exit 0
BOOTSTRAP_ROOT
ASTRONA_STUDENT_SCRIPT
