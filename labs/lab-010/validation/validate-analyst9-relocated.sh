#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Confirms analyst9's primary group is finance, home is /home/accounts/analyst9, and files moved
set -u

primary_group=$(id -gn analyst9 2>/dev/null)
if [[ "$primary_group" != "finance" ]]; then
  echo "FAIL: analyst9 relocated - primary group is '$primary_group', expected 'finance'"
  exit 1
fi

home_dir=$(getent passwd analyst9 | cut -d: -f6)
if [[ "$home_dir" != "/home/accounts/analyst9" ]]; then
  echo "FAIL: analyst9 relocated - home directory is '$home_dir', expected '/home/accounts/analyst9'"
  exit 1
fi

if [[ ! -f "/home/accounts/analyst9/forecast.txt" ]]; then
  echo "FAIL: analyst9 relocated - forecast.txt is missing from the new home directory"
  exit 1
fi

if [[ -d "/home/analyst9" ]] && [[ -f "/home/analyst9/forecast.txt" ]]; then
  echo "FAIL: analyst9 relocated - forecast.txt is still present at the old home directory"
  exit 1
fi

echo "PASS: analyst9 has primary group finance, home /home/accounts/analyst9, files moved."
exit 0
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
