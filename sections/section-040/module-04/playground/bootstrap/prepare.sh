#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
sudo -n bash <<'BOOTSTRAP_ROOT'
# OS prep for PLAYGROUND — Home Directories For Directory Users
# Runs once when the environment comes up. Reproduces Modules 1-2's finished
# state plus a wired sssd client and a second user `newcomer` (UID 10002).
# pam_mkhomedir is OFF and no home folders exist. Nothing to solve.
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
printf '%s\n' 'TLS_CACERT /etc/ldap/certs/ldap-server.crt' 'TLS_REQCERT demand' > /etc/ldap/ldap.conf
systemctl restart slapd
sleep 2

# --- populate the directory (Module 2's output) -----------------------
cat > /tmp/pg-data.ldif <<'EOF'
dn: dc=example,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: LFCS directory
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
EOF
ldapadd -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f /tmp/pg-data.ldif
ldappasswd -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 \
    -s 'LfcsLdap!2024' "uid=lfcsuser,ou=people,dc=example,dc=com"

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
ldapadd -x -D "cn=admin,dc=example,dc=com" -w 'LdapRoot!2024' -H ldap://127.0.0.1 -f /tmp/newcomer.ldif
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

# mkhomedir is deliberately NOT enabled: that is what the reader does.
pam-auth-update --remove mkhomedir >/dev/null 2>&1 || true
sed -i '/pam_mkhomedir/d' /etc/pam.d/common-session

rm -f /tmp/pg-cfg.ldif /tmp/pg-data.ldif
echo "[playground] ready. sssd wired; users lfcsuser and newcomer resolve; no homes, mkhomedir off."
BOOTSTRAP_ROOT
ASTRONA_STUDENT_SCRIPT
