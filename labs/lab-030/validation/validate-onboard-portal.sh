#!/usr/bin/env bash
# Confirms ONBOARD_PORTAL is exported system-wide for login shells via a
# real /etc/profile.d/ script (not /etc/environment, not a per-user dotfile).

set -u

matches=$(grep -rl 'ONBOARD_PORTAL' /etc/profile.d/*.sh 2>/dev/null || true)
if [[ -z "$matches" ]]; then
  echo "FAIL: onboard portal - no /etc/profile.d/*.sh script sets ONBOARD_PORTAL"
  exit 1
fi

if ! grep -h 'ONBOARD_PORTAL' /etc/profile.d/*.sh 2>/dev/null | grep -q 'export'; then
  echo "FAIL: onboard portal - ONBOARD_PORTAL is set in /etc/profile.d/ but never exported"
  exit 1
fi

value=$(su - candidate -c 'echo $ONBOARD_PORTAL' 2>/dev/null || true)
if [[ "$value" != "https://portal.internal/onboarding" ]]; then
  echo "FAIL: onboard portal - not visible or wrong value in a fresh login session (got '$value')"
  exit 1
fi

echo "PASS: ONBOARD_PORTAL correctly set system-wide via /etc/profile.d/ for login shells"
exit 0
