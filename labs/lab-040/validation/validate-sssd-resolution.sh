#!/usr/bin/env bash
# Confirms sssd.conf/nsswitch.conf are correctly wired and lfcsuser/developers
# resolve via NSS.

set -u

if ! systemctl is-active --quiet sssd; then
  echo "FAIL: sssd is not active"
  exit 1
fi

perms=$(stat -c '%a %U %G' /etc/sssd/sssd.conf 2>/dev/null)
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

echo "PASS: sssd.conf/nsswitch.conf are correctly wired and lfcsuser/developers resolve via NSS."
exit 0
