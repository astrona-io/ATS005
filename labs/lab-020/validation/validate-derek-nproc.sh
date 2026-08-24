#!/usr/bin/env bash
# Confirms a proper hard nproc limit for derek exists under limits.d,
# matches the originally planted soft value, and the .bashrc hack is removed.

set -u

MARKER="/var/lib/lab-020/original-soft-nproc"
if [[ ! -f "$MARKER" ]]; then
  echo "FAIL: internal marker file missing - lab bootstrap did not run correctly"
  exit 1
fi
expected=$(cat "$MARKER")

hit=$(grep -rhE '^[[:space:]]*derek[[:space:]]+hard[[:space:]]+nproc[[:space:]]+[0-9]+' \
  /etc/security/limits.conf /etc/security/limits.d/*.conf 2>/dev/null | tail -1)

if [[ -z "$hit" ]]; then
  echo "FAIL: no 'derek hard nproc <value>' entry found in limits.conf or limits.d"
  exit 1
fi

found=$(echo "$hit" | awk '{print $4}')
if [[ "$found" != "$expected" ]]; then
  echo "FAIL: derek's hard nproc limit is '$found', expected '$expected' (the originally effective soft limit)"
  exit 1
fi

if grep -q "ulimit -Sp" /home/derek/.bashrc 2>/dev/null; then
  echo "FAIL: the old '.bashrc' ulimit hack is still present for derek - it should be removed"
  exit 1
fi

echo "PASS: derek's proper hard nproc limit ($found) is set via limits.d, and the .bashrc hack is removed"
exit 0
