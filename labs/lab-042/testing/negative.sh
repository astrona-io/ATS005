#!/usr/bin/env bash
set -euo pipefail
ldappasswd -x -ZZ -D cn=admin,dc=example,dc=com -w 'LdapRoot!2024' -H ldap://127.0.0.1 -s WrongTrainingPassword uid=lfcsuser,ou=people,dc=example,dc=com
