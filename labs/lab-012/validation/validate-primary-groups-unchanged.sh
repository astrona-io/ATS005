#!/usr/bin/env bash
# Confirms marta and cilla's primary group is still staff (unchanged by the datateam addition)
set -u

for u in marta cilla; do
  primary_group=$(id -gn "$u" 2>/dev/null)
  if [[ "$primary_group" != "staff" ]]; then
    echo "FAIL: primary groups unchanged - $u's primary group is '$primary_group', expected 'staff'"
    exit 1
  fi
done

echo "PASS: marta and cilla's primary group is still staff."
exit 0
