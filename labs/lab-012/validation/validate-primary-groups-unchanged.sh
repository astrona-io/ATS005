#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
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
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
