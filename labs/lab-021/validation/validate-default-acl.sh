#!/usr/bin/env bash
# Confirms default ACL entries exist on /srv/projects/orion and that a
# brand-new file created under it automatically inherits both named entries

set -u

TARGET="/srv/projects/orion"

acl_out=$(getfacl -p "$TARGET" 2>/dev/null)

if ! echo "$acl_out" | grep -qE '^default:user:contractor-jane:rwx'; then
  echo "FAIL: no default ACL entry for contractor-jane on $TARGET - new files won't inherit access"
  exit 1
fi

if ! echo "$acl_out" | grep -qE '^default:user:auditor-tom:r-x'; then
  echo "FAIL: no default ACL entry for auditor-tom on $TARGET - new files won't inherit access"
  exit 1
fi

probe_file="$TARGET/.validation-probe-$$"
if ! su -s /bin/bash -c "touch '$probe_file'" team-lead >/dev/null 2>&1; then
  echo "FAIL: could not create probe file as team-lead to test inheritance"
  exit 1
fi

probe_acl=$(getfacl -p "$probe_file" 2>/dev/null)
rm -f "$probe_file"

if ! echo "$probe_acl" | grep -qE '^user:contractor-jane:rwx'; then
  echo "FAIL: newly created file did not inherit contractor-jane's rwx ACL entry - default ACL inheritance is not working"
  exit 1
fi

if ! echo "$probe_acl" | grep -qE '^user:auditor-tom:r-x'; then
  echo "FAIL: newly created file did not inherit auditor-tom's r-x ACL entry - default ACL inheritance is not working"
  exit 1
fi

echo "PASS: default ACL entries present and correctly inherited by a newly created file"
exit 0
