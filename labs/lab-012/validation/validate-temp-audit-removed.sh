#!/usr/bin/env bash
# Confirms temp-audit no longer exists
set -u

if getent group temp-audit >/dev/null 2>&1; then
  echo "FAIL: temp-audit removed - group still exists"
  exit 1
fi

echo "PASS: temp-audit no longer exists."
exit 0
