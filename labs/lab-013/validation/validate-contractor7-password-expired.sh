#!/usr/bin/env bash
# Confirms contractor7's password is expired, forcing a reset on next login
set -u

if ! id contractor7 >/dev/null 2>&1; then
  echo "FAIL: contractor7 password expired - account does not exist"
  exit 1
fi

lastchange=$(sudo getent shadow contractor7 2>/dev/null | cut -d: -f3)
if [[ "$lastchange" != "0" ]]; then
  echo "FAIL: contractor7 password expired - shadow 'last changed' field is '$lastchange', expected '0' (forced reset)"
  exit 1
fi

echo "PASS: contractor7's password is expired, forcing a reset on next login."
exit 0
