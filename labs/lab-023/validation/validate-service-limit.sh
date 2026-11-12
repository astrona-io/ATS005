#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Confirms ledger-sync runs with an open-file limit of 4096, in the unit and on
# the real process.

set -u

UNIT="ledger-sync.service"

if ! systemctl is-active --quiet "$UNIT"; then
  echo "FAIL: $UNIT is not running"
  exit 1
fi

unit_limit=$(systemctl show "$UNIT" -p LimitNOFILE --value)
if [ "$unit_limit" != "4096" ]; then
  echo "FAIL: systemctl reports LimitNOFILE=$unit_limit for $UNIT, expected 4096 (did you run daemon-reload?)"
  exit 1
fi

main_pid=$(systemctl show "$UNIT" -p MainPID --value)
if [ -z "$main_pid" ] || [ "$main_pid" = "0" ] || [ ! -r "/proc/$main_pid/limits" ]; then
  echo "FAIL: could not find the main process of $UNIT"
  exit 1
fi

process_line=$(grep 'Max open files' "/proc/$main_pid/limits")
soft_limit=$(echo "$process_line" | awk '{print $4}')
hard_limit=$(echo "$process_line" | awk '{print $5}')

if [ "$soft_limit" != "4096" ] || [ "$hard_limit" != "4096" ]; then
  echo "FAIL: the running process has soft=$soft_limit hard=$hard_limit open files, expected 4096 (restart the service after the change)"
  exit 1
fi

echo "PASS: ledger-sync runs with 4096 open files in its unit and on the running process"
exit 0
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
