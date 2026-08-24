#!/usr/bin/env bash
# Confirms ou=people/ou=groups, the developers posixGroup, and the lfcsuser
# posixAccount all exist with the correct attributes, and that an
# authenticated bind as lfcsuser succeeds over StartTLS.

set -u

BASE_DN="dc=example,dc=com"
ADMIN_DN="cn=admin,dc=example,dc=com"
ADMIN_PASSWORD="LdapRoot!2024"
LFCS_PASSWORD="LfcsLdap!2024"

search() {
  ldapsearch -x -ZZ -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -H ldap://127.0.0.1 -b "$BASE_DN" "$@" 2>/tmp/lab042-search.log
}

if ! search "(ou=people)" dn >/tmp/lab042-people.log; then
  echo "FAIL: could not search the directory as admin over StartTLS (admin bind or TLS broken)"
  cat /tmp/lab042-search.log
  exit 1
fi
if ! grep -qi "^dn: ou=people,${BASE_DN}" /tmp/lab042-people.log; then
  echo "FAIL: ou=people,${BASE_DN} does not exist"
  exit 1
fi

if ! search "(ou=groups)" dn >/tmp/lab042-groups.log; then
  echo "FAIL: could not search for ou=groups"
  exit 1
fi
if ! grep -qi "^dn: ou=groups,${BASE_DN}" /tmp/lab042-groups.log; then
  echo "FAIL: ou=groups,${BASE_DN} does not exist"
  exit 1
fi

if ! search "(cn=developers)" gidNumber >/tmp/lab042-group.log; then
  echo "FAIL: could not search for the developers group"
  exit 1
fi
if ! grep -q "^gidNumber: 5000" /tmp/lab042-group.log; then
  echo "FAIL: developers group missing or gidNumber is not 5000"
  cat /tmp/lab042-group.log
  exit 1
fi

if ! search "(uid=lfcsuser)" uidNumber gidNumber homeDirectory loginShell >/tmp/lab042-user.log; then
  echo "FAIL: could not search for lfcsuser"
  exit 1
fi
if ! grep -q "^uidNumber: 10001" /tmp/lab042-user.log; then
  echo "FAIL: lfcsuser uidNumber is not 10001"
  cat /tmp/lab042-user.log
  exit 1
fi
if ! grep -q "^gidNumber: 5000" /tmp/lab042-user.log; then
  echo "FAIL: lfcsuser gidNumber is not 5000"
  exit 1
fi
if ! grep -q "^homeDirectory: /home/lfcsuser" /tmp/lab042-user.log; then
  echo "FAIL: lfcsuser homeDirectory is not /home/lfcsuser"
  exit 1
fi
if ! grep -q "^loginShell: /bin/bash" /tmp/lab042-user.log; then
  echo "FAIL: lfcsuser loginShell is not /bin/bash"
  exit 1
fi

whoami_out=$(ldapwhoami -x -D "uid=lfcsuser,ou=people,${BASE_DN}" -w "$LFCS_PASSWORD" -ZZ -H ldap://127.0.0.1 2>/tmp/lab042-whoami.log)
if [[ $? -ne 0 ]] || ! echo "$whoami_out" | grep -qi "uid=lfcsuser"; then
  echo "FAIL: authenticated bind as lfcsuser with the expected password over StartTLS did not succeed"
  cat /tmp/lab042-whoami.log 2>/dev/null
  exit 1
fi

rm -f /tmp/lab042-search.log /tmp/lab042-people.log /tmp/lab042-groups.log /tmp/lab042-group.log /tmp/lab042-user.log /tmp/lab042-whoami.log

echo "PASS: ou=people/ou=groups, developers (gid 5000), and lfcsuser (uid 10001) all exist and bind correctly over TLS."
exit 0
