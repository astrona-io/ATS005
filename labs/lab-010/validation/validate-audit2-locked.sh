#!/usr/bin/env bash
# Confirms audit2 is locked out via the password field without being deleted
set -u

if ! id audit2 >/dev/null 2>&1; then
  echo "FAIL: audit2 locked - account no longer exists; it should be locked, not deleted"
  exit 1
fi

status=$(sudo passwd -S audit2 2>/dev/null | awk '{print $2}')
if [[ "$status" != "L" ]]; then
  echo "FAIL: audit2 locked - passwd -S reports status '$status', expected 'L' (locked)"
  exit 1
fi

echo "PASS: audit2 is locked (passwd -S: L) without being deleted."
exit 0
