#!/usr/bin/env bash
# Confirms a proper hard nproc limit for jackie exists under limits.d,
# matches the soft value originally planted (read dynamically, not hardcoded),
# and the old .bashrc hack has been removed.

set -u

MARKER="/var/lib/lab-022/original-soft-nproc"
if [[ ! -f "$MARKER" ]]; then
  echo "FAIL: internal marker file missing - lab bootstrap did not run correctly"
  exit 1
fi
expected=$(cat "$MARKER")

hit=$(grep -rhE '^[[:space:]]*jackie[[:space:]]+hard[[:space:]]+nproc[[:space:]]+[0-9]+' \
  /etc/security/limits.conf /etc/security/limits.d/*.conf 2>/dev/null | tail -1)

if [[ -z "$hit" ]]; then
  echo "FAIL: no 'jackie hard nproc <value>' entry found in limits.conf or limits.d"
  exit 1
fi

found=$(echo "$hit" | awk '{print $4}')
if [[ "$found" != "$expected" ]]; then
  echo "FAIL: jackie's hard nproc limit is '$found', expected '$expected' (the originally effective soft limit)"
  exit 1
fi

if grep -q "ulimit -Sp" /home/jackie/.bashrc 2>/dev/null; then
  echo "FAIL: the old '.bashrc' ulimit hack is still present - it should be removed now that the proper limit is set"
  exit 1
fi

echo "PASS: jackie's proper hard nproc limit ($found) is set via limits.d, and the .bashrc hack is removed"
exit 0
