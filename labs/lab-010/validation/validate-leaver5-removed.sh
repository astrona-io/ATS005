#!/usr/bin/env bash
# Confirms leaver5 and their home directory are fully removed
set -u

if id leaver5 >/dev/null 2>&1; then
  echo "FAIL: leaver5 removed - account still exists"
  exit 1
fi

if [[ -d "/home/leaver5" ]]; then
  echo "FAIL: leaver5 removed - home directory /home/leaver5 still exists (userdel -r was required)"
  exit 1
fi

echo "PASS: leaver5 and its home directory are fully removed."
exit 0
