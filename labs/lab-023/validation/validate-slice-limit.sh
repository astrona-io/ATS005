#!/usr/bin/env bash
# Confirms the slice of UID 2010 has TasksMax=100 and that the setting is saved
# in a drop-in file (not only set for the current boot).

set -u

SLICE="user-2010.slice"

tasks_max=$(systemctl show "$SLICE" -p TasksMax --value)
if [ "$tasks_max" != "100" ]; then
  echo "FAIL: systemctl reports TasksMax=$tasks_max for $SLICE, expected 100"
  exit 1
fi

saved_in_file=0
for folder in /etc/systemd/system/user-2010.slice.d /etc/systemd/system.control/user-2010.slice.d; do
  if [ -d "$folder" ] && grep -rqE '^[[:space:]]*TasksMax=100[[:space:]]*$' "$folder" 2>/dev/null; then
    saved_in_file=1
  fi
done

if [ "$saved_in_file" -ne 1 ]; then
  echo "FAIL: no saved drop-in sets TasksMax=100 for $SLICE (a runtime-only change is lost at reboot)"
  exit 1
fi

echo "PASS: $SLICE has TasksMax=100 and the setting is saved in a drop-in"
exit 0
