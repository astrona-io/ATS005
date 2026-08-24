#!/usr/bin/env bash
# Confirms local accounts (root) still resolve and behave exactly as before
# the LDAP/sssd integration, proving nsswitch.conf ordering ("files" before
# "sss") kept local accounts safe.

set -u

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

if ! su - root -c 'true' >/dev/null 2>&1; then
  echo "FAIL: 'su - root' sanity check failed - local authentication path may be broken"
  exit 1
fi

passwd_line=$(grep -E '^passwd:' /etc/nsswitch.conf 2>/dev/null)
if [[ "$passwd_line" != files* ]]; then
  echo "FAIL: 'files' is no longer the first source on the nsswitch.conf 'passwd' line: '${passwd_line:-<missing>}'"
  exit 1
fi

echo "PASS: local accounts (root) remain fully functional and 'files' still precedes 'sss' in nsswitch.conf."
exit 0
