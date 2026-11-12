#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Confirms legacy-ops was renamed to platform-ops with GID 4200 and membership preserved
set -u

if getent group legacy-ops >/dev/null 2>&1; then
  echo "FAIL: platform-ops renamed - legacy-ops still exists; it should have been renamed, not left in place"
  exit 1
fi

entry=$(getent group platform-ops 2>/dev/null)
if [[ -z "$entry" ]]; then
  echo "FAIL: platform-ops renamed - platform-ops does not exist"
  exit 1
fi

gid=$(cut -d: -f3 <<< "$entry")
if [[ "$gid" != "4200" ]]; then
  echo "FAIL: platform-ops renamed - GID is '$gid', expected '4200' (unchanged from legacy-ops)"
  exit 1
fi

members=$(cut -d: -f4 <<< "$entry")
if ! grep -qw "opadmin" <<< "$members"; then
  echo "FAIL: platform-ops renamed - original member 'opadmin' is missing (members: $members)"
  exit 1
fi

echo "PASS: platform-ops exists with GID 4200 and preserved membership, legacy-ops is gone."
exit 0
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
