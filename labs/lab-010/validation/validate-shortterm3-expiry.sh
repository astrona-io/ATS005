#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Confirms shortterm3's account is set to fully expire in ~14 days
set -u

if ! id shortterm3 >/dev/null 2>&1; then
  echo "FAIL: shortterm3 expiry - account does not exist"
  exit 1
fi

expire_days=$(sudo getent shadow shortterm3 2>/dev/null | cut -d: -f8)
if [[ -z "$expire_days" ]]; then
  echo "FAIL: shortterm3 expiry - no expiration date set (shadow expire field is empty)"
  exit 1
fi

now_days=$(( $(date +%s) / 86400 ))
delta=$(( expire_days - now_days ))

if (( delta < 10 || delta > 18 )); then
  echo "FAIL: shortterm3 expiry - expires in $delta day(s) from now, expected approximately 14"
  exit 1
fi

echo "PASS: shortterm3's account expires in $delta day(s), matching the required ~14-day expiration."
exit 0
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
