#!/usr/bin/env bash
# Confirms /etc/sudoers.d/webops exists with the right owner and mode, defines
# the SERVICE_CMDS alias, and that every sudoers file passes visudo -c.

set -u

FILE="/etc/sudoers.d/webops"

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist (the file name must be exactly 'webops', with no dot)"
  exit 1
fi

owner_group=$(stat -c '%U:%G' "$FILE")
mode=$(stat -c '%a' "$FILE")

if [ "$owner_group" != "root:root" ]; then
  echo "FAIL: $FILE is owned by $owner_group, expected root:root"
  exit 1
fi

if [ "$mode" != "440" ]; then
  echo "FAIL: $FILE has mode $mode, expected 440"
  exit 1
fi

if ! grep -qE '^[[:space:]]*Cmnd_Alias[[:space:]]+SERVICE_CMDS[[:space:]]*=' "$FILE"; then
  echo "FAIL: $FILE does not define a Cmnd_Alias named SERVICE_CMDS"
  exit 1
fi

if ! visudo -c >/dev/null 2>&1; then
  echo "FAIL: visudo -c reports an error in the sudoers files"
  exit 1
fi

echo "PASS: webops drop-in has the right owner, mode and alias, and visudo -c is clean"
exit 0
