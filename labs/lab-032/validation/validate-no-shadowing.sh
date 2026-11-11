#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Plants a same-named decoy script in ~/work and confirms it never wins over
# the real system command, proving PATH was appended rather than prepended.

set -u

decoy="/home/candidate/work/ls"
cleanup() {
  rm -f "$decoy"
}
trap cleanup EXIT

cat > "$decoy" <<'EOF'
#!/bin/bash
echo "decoy ls - should never run"
EOF
chmod +x "$decoy"
chown candidate:candidate "$decoy"

resolved=$(sudo su - candidate -c 'hash -r; type -P ls' 2>/dev/null || true)

if [[ -z "$resolved" ]]; then
  echo "FAIL: no-shadowing - could not resolve 'ls' at all for candidate"
  exit 1
fi

if [[ "$resolved" == "/home/candidate/work/ls" ]]; then
  echo "FAIL: no-shadowing - the decoy ~/work/ls shadowed the real system 'ls' command"
  exit 1
fi

output=$(sudo su - candidate -c 'hash -r; ls /home/candidate/work' 2>/dev/null || true)
if echo "$output" | grep -q 'decoy ls'; then
  echo "FAIL: no-shadowing - running 'ls' actually executed the decoy script instead of the real binary"
  exit 1
fi

echo "PASS: real system 'ls' still resolves first; ~/work does not shadow existing commands"
exit 0
ASTRONA_STUDENT_SCRIPT
