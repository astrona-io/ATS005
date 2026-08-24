#!/usr/bin/env bash
# Confirms default ACL entries exist on /srv/data/atlas and that a brand-new
# file created under it automatically inherits both named entries

set -u

TARGET="/srv/data/atlas"

acl_out=$(getfacl -p "$TARGET" 2>/dev/null)

if ! echo "$acl_out" | grep -qE '^default:user:vendor-lee:rwx'; then
  echo "FAIL: no default ACL entry for vendor-lee on $TARGET - new files won't inherit access"
  exit 1
fi

if ! echo "$acl_out" | grep -qE '^default:user:qa-nina:r-x'; then
  echo "FAIL: no default ACL entry for qa-nina on $TARGET - new files won't inherit access"
  exit 1
fi

probe_file="$TARGET/.validation-probe-$$"
if ! su -s /bin/bash -c "touch '$probe_file'" lead-dev >/dev/null 2>&1; then
  echo "FAIL: could not create probe file as lead-dev to test inheritance"
  exit 1
fi

probe_acl=$(getfacl -p "$probe_file" 2>/dev/null)
rm -f "$probe_file"

if ! echo "$probe_acl" | grep -qE '^user:vendor-lee:rwx'; then
  echo "FAIL: newly created file did not inherit vendor-lee's rwx ACL entry - default ACL inheritance is not working"
  exit 1
fi

if ! echo "$probe_acl" | grep -qE '^user:qa-nina:r-x'; then
  echo "FAIL: newly created file did not inherit qa-nina's r-x ACL entry - default ACL inheritance is not working"
  exit 1
fi

echo "PASS: default ACL entries present and correctly inherited by a newly created file"
exit 0
