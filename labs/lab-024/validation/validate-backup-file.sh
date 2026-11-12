#!/usr/bin/env bash
# Read the ACL backup without changing permissions on /root.
sudo -H bash <<'ASTRONA_STUDENT_SCRIPT'
# Confirms the backup file was saved with the full ACL of the tree.
set -u

B=/root/ledger-acl.backup

if [ ! -s "$B" ]; then
  echo "FAIL: $B does not exist or is empty"
  exit 1
fi

if ! grep -q '^# file: /srv/data/ledger/2025/q1.csv' "$B"; then
  echo "FAIL: the backup has no absolute paths for the tree (save it with getfacl -R -p)"
  exit 1
fi

for pattern in 'user:auditor-ivy:' 'user:temp-vendor:' 'user:ledger-clerk:rw-' 'default:user:auditor-ivy:r-x'; do
  if ! grep -q "^$pattern" "$B"; then
    echo "FAIL: the backup has no line starting with $pattern (was it saved before the cleanup?)"
    exit 1
  fi
done

echo "PASS: the backup holds the named, clerk and default entries of the tree"
exit 0
ASTRONA_STUDENT_SCRIPT
