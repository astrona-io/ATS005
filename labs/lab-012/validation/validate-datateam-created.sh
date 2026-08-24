#!/usr/bin/env bash
# Confirms datateam exists with GID 5000 and marta+cilla as members
set -u

entry=$(getent group datateam 2>/dev/null)
if [[ -z "$entry" ]]; then
  echo "FAIL: datateam created - group does not exist"
  exit 1
fi

gid=$(cut -d: -f3 <<< "$entry")
if [[ "$gid" != "5000" ]]; then
  echo "FAIL: datateam created - GID is '$gid', expected '5000'"
  exit 1
fi

members=$(cut -d: -f4 <<< "$entry")
for u in marta cilla; do
  if ! grep -qw "$u" <<< "$members"; then
    echo "FAIL: datateam created - member '$u' missing (members: $members)"
    exit 1
  fi
done

echo "PASS: datateam exists with GID 5000 and marta+cilla as members."
exit 0
