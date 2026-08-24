#!/usr/bin/env bash
# Confirms contractor1 and their home directory are fully removed
set -u

if id contractor1 >/dev/null 2>&1; then
  echo "FAIL: contractor1 removed - account still exists"
  exit 1
fi

if [[ -d "/home/contractor1" ]]; then
  echo "FAIL: contractor1 removed - home directory /home/contractor1 still exists (userdel -r was required)"
  exit 1
fi

echo "PASS: contractor1 and its home directory are fully removed."
exit 0
