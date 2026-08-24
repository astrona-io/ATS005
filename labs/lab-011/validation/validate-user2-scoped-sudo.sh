#!/usr/bin/env bash
# Confirms user2 can run 'sudo bash /root/dangerous.sh' NOPASSWD, and the grant isn't a blanket ALL rule
set -u

sudo_list=$(sudo -l -U user2 2>/dev/null)

if grep -qE 'NOPASSWD:\s*ALL\b' <<< "$sudo_list"; then
  echo "FAIL: user2 scoped sudo - a blanket 'NOPASSWD: ALL' rule was found; the grant must be scoped to the exact command"
  exit 1
fi

if ! grep -q "dangerous.sh" <<< "$sudo_list"; then
  echo "FAIL: user2 scoped sudo - no sudo rule referencing dangerous.sh found for user2"
  exit 1
fi

output=$(su - user2 -c "sudo -n bash /root/dangerous.sh" 2>&1)
status=$?
if [[ $status -ne 0 ]]; then
  echo "FAIL: user2 scoped sudo - 'sudo -n bash /root/dangerous.sh' did not succeed non-interactively (output: $output)"
  exit 1
fi

if ! grep -q "dangerous script executed as root" <<< "$output"; then
  echo "FAIL: user2 scoped sudo - script did not run as root (output: $output)"
  exit 1
fi

echo "PASS: user2 can run the exact NOPASSWD command as root, with no blanket grant."
exit 0
