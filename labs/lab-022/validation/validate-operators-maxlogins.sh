#!/usr/bin/env bash
# Confirms an @operators hard maxlogins 1 entry exists under limits.conf/limits.d

set -u

hit=$(grep -rhE '^[[:space:]]*@operators[[:space:]]+hard[[:space:]]+maxlogins[[:space:]]+1[[:space:]]*$' \
  /etc/security/limits.conf /etc/security/limits.d/*.conf 2>/dev/null)

if [[ -z "$hit" ]]; then
  echo "FAIL: no '@operators hard maxlogins 1' entry found in limits.conf or limits.d"
  exit 1
fi

echo "PASS: @operators hard maxlogins 1 is configured"
exit 0
