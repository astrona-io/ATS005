#!/usr/bin/env bash
# Confirms user2 exists with groups dev+op, home /home/accounts/user2, and shell /bin/bash
set -u

if ! id user2 >/dev/null 2>&1; then
  echo "FAIL: user2 provisioned - account does not exist"
  exit 1
fi

groups_list=$(id -Gn user2 2>/dev/null)
for g in dev op; do
  if ! grep -qw "$g" <<< "$groups_list"; then
    echo "FAIL: user2 provisioned - missing expected group '$g' (has: $groups_list)"
    exit 1
  fi
done

home_dir=$(getent passwd user2 | cut -d: -f6)
if [[ "$home_dir" != "/home/accounts/user2" ]]; then
  echo "FAIL: user2 provisioned - home directory is '$home_dir', expected '/home/accounts/user2'"
  exit 1
fi

shell=$(getent passwd user2 | cut -d: -f7)
if [[ "$shell" != "/bin/bash" ]]; then
  echo "FAIL: user2 provisioned - shell is '$shell', expected '/bin/bash'"
  exit 1
fi

echo "PASS: user2 exists with groups dev+op, home /home/accounts/user2, shell /bin/bash."
exit 0
