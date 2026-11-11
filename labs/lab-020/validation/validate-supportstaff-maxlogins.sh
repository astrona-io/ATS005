#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Confirms an @supportstaff hard maxlogins 1 entry exists under limits.d

set -u

hit=$(grep -rhE '^[[:space:]]*@supportstaff[[:space:]]+hard[[:space:]]+maxlogins[[:space:]]+1[[:space:]]*$' \
  /etc/security/limits.conf /etc/security/limits.d/*.conf 2>/dev/null)

if [[ -z "$hit" ]]; then
  echo "FAIL: no '@supportstaff hard maxlogins 1' entry found in limits.conf or limits.d"
  exit 1
fi

echo "PASS: @supportstaff hard maxlogins 1 is configured"
exit 0
ASTRONA_STUDENT_SCRIPT
