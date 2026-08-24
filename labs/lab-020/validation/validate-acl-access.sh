#!/usr/bin/env bash
# Confirms named ACL entries for vendor-lee (rwx) and qa-nina (r-x) exist on
# /srv/data/atlas and pre-existing content/ownership are intact

set -u

TARGET="/srv/data/atlas"

if [[ ! -d "$TARGET" ]]; then
  echo "FAIL: $TARGET does not exist"
  exit 1
fi

owner=$(stat -c '%U' "$TARGET")
group=$(stat -c '%G' "$TARGET")
if [[ "$owner" != "lead-dev" || "$group" != "atlas-team" ]]; then
  echo "FAIL: $TARGET owner/group changed - expected lead-dev:atlas-team, found $owner:$group"
  exit 1
fi

acl_out=$(getfacl -p "$TARGET" 2>/dev/null)

lee_entry=$(echo "$acl_out" | grep -E '^user:vendor-lee:' || true)
if [[ -z "$lee_entry" || "$lee_entry" != *"rwx"* ]]; then
  echo "FAIL: vendor-lee's ACL entry on $TARGET is '$lee_entry', expected rwx"
  exit 1
fi

nina_entry=$(echo "$acl_out" | grep -E '^user:qa-nina:' || true)
if [[ -z "$nina_entry" || "$nina_entry" != *"r-x"* ]]; then
  echo "FAIL: qa-nina's ACL entry on $TARGET is '$nina_entry', expected r-x"
  exit 1
fi

for f in "$TARGET/README.txt" "$TARGET/exports/summary.txt"; do
  entry_out=$(getfacl -p "$f" 2>/dev/null)
  if ! echo "$entry_out" | grep -qE '^user:vendor-lee:rwx'; then
    echo "FAIL: pre-existing file $f is missing vendor-lee's recursive rwx ACL entry"
    exit 1
  fi
  if ! echo "$entry_out" | grep -qE '^user:qa-nina:r-x'; then
    echo "FAIL: pre-existing file $f is missing qa-nina's recursive r-x ACL entry"
    exit 1
  fi
done

echo "PASS: vendor-lee (rwx) and qa-nina (r-x) ACL entries are correctly applied, owner/group unchanged"
exit 0
