#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Confirms temp-audit no longer exists
set -u

if getent group temp-audit >/dev/null 2>&1; then
  echo "FAIL: temp-audit removed - group still exists"
  exit 1
fi

echo "PASS: temp-audit no longer exists."
exit 0
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
