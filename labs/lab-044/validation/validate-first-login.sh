#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Adds a brand new directory user at grading time, runs a login as that user,
# and checks the home that the login created.
set -u

ADMIN_DN="cn=admin,dc=example,dc=com"
ADMIN_PASSWORD="LdapRoot!2024"
PROBE="gradeprobe"

if ! getent passwd newcomer >/dev/null; then
  echo "FAIL: newcomer no longer resolves, so sssd or nsswitch was broken"
  exit 1
fi

if ! getent passwd "$PROBE" >/dev/null; then
  cat > /tmp/gradeprobe.ldif <<LDIF
dn: uid=${PROBE},ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: Grade Probe
sn: Probe
uid: ${PROBE}
uidNumber: 10090
gidNumber: 5000
homeDirectory: /home/${PROBE}
loginShell: /bin/bash
LDIF
  if ! ldapadd -x -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -H ldap://127.0.0.1 -f /tmp/gradeprobe.ldif >/dev/null 2>&1; then
    echo "FAIL: the grader could not add its probe user to the directory"
    exit 1
  fi
  rm -f /tmp/gradeprobe.ldif
  # allow sssd to see the new entry
  sss_cache -E >/dev/null 2>&1 || true
  sleep 2
fi

if ! getent passwd "$PROBE" >/dev/null; then
  echo "FAIL: the probe user does not resolve through sssd"
  exit 1
fi

rm -rf "/home/$PROBE"

sudo su - "$PROBE" -c true >/dev/null 2>&1

if [ ! -d "/home/$PROBE" ]; then
  echo "FAIL: a first login did not create /home/$PROBE"
  exit 1
fi

owner=$(stat -c %U "/home/$PROBE")
if [ "$owner" != "$PROBE" ]; then
  echo "FAIL: /home/$PROBE is owned by $owner, expected $PROBE"
  exit 1
fi

if [ ! -f "/home/$PROBE/WELCOME.txt" ]; then
  echo "FAIL: /home/$PROBE/WELCOME.txt is missing, so /etc/skel was not copied"
  exit 1
fi

if [ ! -f "/home/$PROBE/.bashrc" ]; then
  echo "FAIL: /home/$PROBE/.bashrc is missing, so the starter kit was not copied"
  exit 1
fi

echo "PASS: a first login created a stocked home owned by the new user"
exit 0
ASTRONA_STUDENT_SCRIPT
