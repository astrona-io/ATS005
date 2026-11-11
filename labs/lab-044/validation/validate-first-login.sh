#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Adds a brand new directory user at grading time, runs a login as that user,
# and checks the home that the login created.
set -u

ADMIN_DN="cn=admin,dc=example,dc=com"
ADMIN_PASSWORD="LdapRoot!2024"
PROBE="gradeprobe$$"
PROBE_UID=$((200000 + $$))
probe_file=$(mktemp)
cleanup() {
  ldapdelete -x -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -H ldap://127.0.0.1 "uid=${PROBE},ou=people,dc=example,dc=com" >/dev/null 2>&1 || true
  rm -f "$probe_file"
  rm -rf "/home/$PROBE"
  sss_cache -E >/dev/null 2>&1 || true
}
trap cleanup EXIT

if ! getent passwd newcomer >/dev/null; then
  echo "FAIL: newcomer no longer resolves, so sssd or nsswitch was broken"
  exit 1
fi

if ! getent passwd "$PROBE" >/dev/null; then
  cat > "$probe_file" <<LDIF
dn: uid=${PROBE},ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: Grade Probe
sn: Probe
uid: ${PROBE}
uidNumber: ${PROBE_UID}
gidNumber: 5000
homeDirectory: /home/${PROBE}
loginShell: /bin/bash
LDIF
  if ! ldapadd -x -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -H ldap://127.0.0.1 -f "$probe_file" >/dev/null 2>&1; then
    echo "FAIL: the grader could not add its probe user to the directory"
    exit 1
  fi
  rm -f "$probe_file"
  # allow sssd to see the new entry
  sss_cache -E >/dev/null 2>&1 || true
  for attempt in $(seq 1 30); do
    getent passwd "$PROBE" >/dev/null && break
    sss_cache -E >/dev/null 2>&1 || true
    sleep 1
  done
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

owner=$(stat -c %u "/home/$PROBE")
if [ "$owner" != "$PROBE_UID" ]; then
  echo "FAIL: /home/$PROBE is owned by UID $owner, expected $PROBE_UID"
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
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
