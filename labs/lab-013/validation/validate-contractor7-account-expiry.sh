#!/usr/bin/env bash
# Confirms contractor7's account is set to expire ~30 days from now (not just the password)
set -u

if ! id contractor7 >/dev/null 2>&1; then
  echo "FAIL: contractor7 account expiry - account does not exist"
  exit 1
fi

expire_days=$(sudo getent shadow contractor7 2>/dev/null | cut -d: -f8)
if [[ -z "$expire_days" ]]; then
  echo "FAIL: contractor7 account expiry - no expiration date set (shadow expire field is empty)"
  exit 1
fi

now_days=$(( $(date +%s) / 86400 ))
delta=$(( expire_days - now_days ))

if (( delta < 25 || delta > 35 )); then
  echo "FAIL: contractor7 account expiry - expires in $delta day(s) from now, expected approximately 30"
  exit 1
fi

echo "PASS: contractor7's account expires in $delta day(s), matching the required ~30-day expiration."
exit 0
