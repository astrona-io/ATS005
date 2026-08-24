#!/usr/bin/env bash
# Confirms user1's primary group is dev, home is /home/accounts/user1, and files actually moved
set -u

primary_group=$(id -gn user1 2>/dev/null)
if [[ "$primary_group" != "dev" ]]; then
  echo "FAIL: user1 relocated - primary group is '$primary_group', expected 'dev'"
  exit 1
fi

home_dir=$(getent passwd user1 | cut -d: -f6)
if [[ "$home_dir" != "/home/accounts/user1" ]]; then
  echo "FAIL: user1 relocated - home directory field is '$home_dir', expected '/home/accounts/user1'"
  exit 1
fi

if [[ ! -f "/home/accounts/user1/important-file.txt" ]]; then
  echo "FAIL: user1 relocated - important-file.txt is missing from the new home directory, contents were not moved"
  exit 1
fi

if [[ -d "/home/user1" ]] && [[ -f "/home/user1/important-file.txt" ]]; then
  echo "FAIL: user1 relocated - important-file.txt is still present at the old home directory /home/user1"
  exit 1
fi

echo "PASS: user1 has primary group dev, home /home/accounts/user1, and files were moved."
exit 0
