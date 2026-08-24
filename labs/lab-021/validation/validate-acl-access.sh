#!/usr/bin/env bash
# Confirms named ACL entries for contractor-jane (rwx) and auditor-tom (r-x)
# exist on /srv/projects/orion and pre-existing content/ownership are intact

set -u

TARGET="/srv/projects/orion"

if [[ ! -d "$TARGET" ]]; then
  echo "FAIL: $TARGET does not exist"
  exit 1
fi

owner=$(stat -c '%U' "$TARGET")
group=$(stat -c '%G' "$TARGET")
if [[ "$owner" != "team-lead" || "$group" != "orion-team" ]]; then
  echo "FAIL: $TARGET owner/group changed - expected team-lead:orion-team, found $owner:$group"
  exit 1
fi

acl_out=$(getfacl -p "$TARGET" 2>/dev/null)

jane_entry=$(echo "$acl_out" | grep -E '^user:contractor-jane:' || true)
if [[ -z "$jane_entry" ]]; then
  echo "FAIL: no ACL entry for contractor-jane on $TARGET"
  exit 1
fi
if [[ "$jane_entry" != *"rwx"* ]]; then
  echo "FAIL: contractor-jane's ACL entry on $TARGET is '$jane_entry', expected rwx"
  exit 1
fi

tom_entry=$(echo "$acl_out" | grep -E '^user:auditor-tom:' || true)
if [[ -z "$tom_entry" ]]; then
  echo "FAIL: no ACL entry for auditor-tom on $TARGET"
  exit 1
fi
if [[ "$tom_entry" != *"r-x"* ]]; then
  echo "FAIL: auditor-tom's ACL entry on $TARGET is '$tom_entry', expected r-x"
  exit 1
fi

for f in "$TARGET/README.txt" "$TARGET/reports/q1.txt"; do
  entry_out=$(getfacl -p "$f" 2>/dev/null)
  if ! echo "$entry_out" | grep -qE '^user:contractor-jane:rwx'; then
    echo "FAIL: pre-existing file $f is missing contractor-jane's recursive rwx ACL entry"
    exit 1
  fi
  if ! echo "$entry_out" | grep -qE '^user:auditor-tom:r-x'; then
    echo "FAIL: pre-existing file $f is missing auditor-tom's recursive r-x ACL entry"
    exit 1
  fi
done

echo "PASS: contractor-jane (rwx) and auditor-tom (r-x) ACL entries are correctly applied, owner/group unchanged"
exit 0
