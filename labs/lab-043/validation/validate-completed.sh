#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Confirms sssd.conf/nsswitch.conf are correctly wired, lfcsuser/developers
# resolve via NSS, and local accounts (root) remain unaffected.

set -u

if ! systemctl is-active --quiet sssd; then
  echo "FAIL: sssd is not active"
  exit 1
fi

perms=$(sudo stat -c '%a %U %G' /etc/sssd/sssd.conf 2>/dev/null)
if [[ "$perms" != "600 root root" ]]; then
  echo "FAIL: /etc/sssd/sssd.conf must be mode 600 owned root:root, got '${perms:-<missing>}'"
  exit 1
fi

passwd_line=$(grep -E '^passwd:' /etc/nsswitch.conf 2>/dev/null)
if [[ "$passwd_line" != *sss* ]]; then
  echo "FAIL: /etc/nsswitch.conf 'passwd' line does not include 'sss': '${passwd_line:-<missing>}'"
  exit 1
fi

group_line=$(grep -E '^group:' /etc/nsswitch.conf 2>/dev/null)
if [[ "$group_line" != *sss* ]]; then
  echo "FAIL: /etc/nsswitch.conf 'group' line does not include 'sss': '${group_line:-<missing>}'"
  exit 1
fi

passwd_entry=$(getent passwd lfcsuser 2>/dev/null)
if [[ -z "$passwd_entry" ]]; then
  echo "FAIL: 'getent passwd lfcsuser' returned nothing - NSS/SSSD/LDAP resolution is broken"
  exit 1
fi
if [[ "$passwd_entry" != *:10001:* ]]; then
  echo "FAIL: lfcsuser did not resolve with UID 10001: '$passwd_entry'"
  exit 1
fi
if [[ "$passwd_entry" != *:/home/lfcsuser:* ]]; then
  echo "FAIL: lfcsuser home directory did not resolve to /home/lfcsuser: '$passwd_entry'"
  exit 1
fi
if [[ "$passwd_entry" != *:/bin/bash ]]; then
  echo "FAIL: lfcsuser shell did not resolve to /bin/bash: '$passwd_entry'"
  exit 1
fi

group_entry=$(getent group developers 2>/dev/null)
if [[ -z "$group_entry" ]]; then
  echo "FAIL: 'getent group developers' returned nothing"
  exit 1
fi
if [[ "$group_entry" != *:5000:* ]]; then
  echo "FAIL: developers group did not resolve with GID 5000: '$group_entry'"
  exit 1
fi

id_out=$(id lfcsuser 2>/dev/null)
if [[ -z "$id_out" ]]; then
  echo "FAIL: 'id lfcsuser' failed"
  exit 1
fi
if [[ "$id_out" != *"uid=10001"* ]]; then
  echo "FAIL: 'id lfcsuser' did not show uid=10001: '$id_out'"
  exit 1
fi

root_passwd=$(getent passwd root 2>/dev/null)
if [[ "$root_passwd" != root:*:0:0:* ]]; then
  echo "FAIL: local root account no longer resolves correctly via files: '${root_passwd:-<missing>}'"
  exit 1
fi

root_id=$(id root 2>/dev/null)
if [[ "$root_id" != *"uid=0(root)"* ]]; then
  echo "FAIL: 'id root' is no longer reporting uid=0: '$root_id'"
  exit 1
fi

# Reject a client that makes the task pass by disabling server authentication.
if ! sudo python3 - <<'CONFIG'
import configparser
cfg = configparser.ConfigParser(interpolation=None)
cfg.read('/etc/sssd/sssd.conf')
sections = [cfg[s] for s in cfg.sections() if s.startswith('domain/') and cfg[s].get('id_provider') == 'ldap']
assert sections, 'No LDAP domain configured'
for domain in sections:
    assert domain.getboolean('ldap_id_use_start_tls', fallback=False), 'StartTLS is required'
    assert domain.get('ldap_tls_reqcert', '').lower() in ('demand', 'hard'), 'Certificate verification is required'
CONFIG
then
  echo 'FAIL: LDAP must require StartTLS and trusted server certificates'
  exit 1
fi

# A fresh directory-only identity cannot be satisfied by cached lfcsuser data.
sudo -n bash <<'VERIFY_ROOT'
set -euo pipefail
fail() { echo "FAIL: $*"; exit 1; }
probe="probe$(openssl rand -hex 6)"
password="$(openssl rand -hex 16)"
uid=$((20000 + RANDOM))
dn="uid=$probe,ou=people,dc=example,dc=com"
cleanup() { ldapdelete -x -H ldap://127.0.0.1 -D cn=admin,dc=example,dc=com -w 'LdapRoot!2024' "$dn" >/dev/null 2>&1 || true; }
trap cleanup EXIT
hash=$(slappasswd -s "$password")
ldapadd -x -H ldap://127.0.0.1 -D cn=admin,dc=example,dc=com -w 'LdapRoot!2024' >/dev/null <<EOF
dn: $dn
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: Fresh LDAP probe
sn: Probe
uid: $probe
uidNumber: $uid
gidNumber: 5000
homeDirectory: /home/$probe
loginShell: /bin/bash
userPassword: $hash
EOF
entry=''
for attempt in $(seq 1 15); do
  entry=$(getent -s sss passwd "$probe" || true)
  [ -n "$entry" ] && break
  sleep 2
done
[ "$(printf '%s' "$entry" | cut -d: -f3)" = "$uid" ] || fail 'fresh LDAP identity did not resolve through SSSD'
# pamtester exercises PAM authentication; root su would skip the password check.
printf '%s\n' "$password" | timeout 15 pamtester lfcs-ldap "$probe" authenticate >/dev/null 2>&1 || fail 'LDAP password authentication failed'
if printf '%s\n' 'deliberately-wrong-password' | timeout 15 pamtester lfcs-ldap "$probe" authenticate >/dev/null 2>&1; then
  fail 'incorrect LDAP password was accepted'
fi
VERIFY_ROOT
status=$?
[ "$status" -eq 0 ] || exit "$status"

echo "PASS: sssd resolves lfcsuser/developers via NSS correctly, and local accounts (root) remain unaffected."
exit 0
ASTRONA_STUDENT_SCRIPT
