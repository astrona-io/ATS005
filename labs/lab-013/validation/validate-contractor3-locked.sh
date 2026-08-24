#!/usr/bin/env bash
# Confirms contractor3 is locked out via the password field, not deleted
set -u

if ! id contractor3 >/dev/null 2>&1; then
  echo "FAIL: contractor3 locked - account no longer exists; it should be locked, not deleted"
  exit 1
fi

status=$(sudo passwd -S contractor3 2>/dev/null | awk '{print $2}')
if [[ "$status" != "L" ]]; then
  echo "FAIL: contractor3 locked - passwd -S reports status '$status', expected 'L' (locked)"
  exit 1
fi

hash=$(sudo getent shadow contractor3 2>/dev/null | cut -d: -f2)
if [[ "$hash" != !* ]]; then
  echo "FAIL: contractor3 locked - shadow password field does not start with '!' (field: $hash)"
  exit 1
fi

echo "PASS: contractor3 is locked (passwd -S: L) without being deleted."
exit 0
