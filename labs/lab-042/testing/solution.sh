#!/usr/bin/env bash
set -euo pipefail
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
