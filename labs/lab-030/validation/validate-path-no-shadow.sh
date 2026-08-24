#!/usr/bin/env bash
# Confirms ~/bin is appended (not prepended) to candidate's PATH, and that a
# same-named decoy script placed there never shadows a real system command.

set -u

effective_path=$(su - candidate -c 'echo $PATH' 2>/dev/null || true)
if [[ -z "$effective_path" ]]; then
  echo "FAIL: PATH capstone - could not read candidate's effective PATH from a fresh login shell"
  exit 1
fi

bin_index=-1
usrbin_index=-1
i=0
IFS=':' read -ra dirs <<< "$effective_path"
for d in "${dirs[@]}"; do
  [[ "$d" == "/home/candidate/bin" ]] && bin_index=$i
  [[ "$d" == "/usr/bin" ]] && usrbin_index=$i
  i=$((i + 1))
done

if [[ "$bin_index" -eq -1 ]]; then
  echo "FAIL: PATH capstone - /home/candidate/bin is not present in candidate's PATH"
  exit 1
fi

if [[ "$usrbin_index" -eq -1 ]]; then
  echo "FAIL: PATH capstone - /usr/bin not found in candidate's PATH at all, cannot verify ordering"
  exit 1
fi

if [[ "$bin_index" -lt "$usrbin_index" ]]; then
  echo "FAIL: PATH capstone - ~/bin appears BEFORE /usr/bin, meaning it was prepended, not appended"
  exit 1
fi

if ! su - candidate -c 'command -v deploy-helper' >/dev/null 2>&1; then
  echo "FAIL: PATH capstone - deploy-helper in ~/bin is not runnable by name from a fresh login shell"
  exit 1
fi

decoy="/home/candidate/bin/id"
cleanup() { rm -f "$decoy"; }
trap cleanup EXIT

cat > "$decoy" <<'EOF'
#!/bin/bash
echo "decoy id - should never run"
EOF
chmod +x "$decoy"
chown candidate:candidate "$decoy"

resolved=$(su - candidate -c 'hash -r; type -P id' 2>/dev/null || true)
if [[ "$resolved" == "/home/candidate/bin/id" ]]; then
  echo "FAIL: PATH capstone - the decoy ~/bin/id shadowed the real system 'id' command"
  exit 1
fi

echo "PASS: ~/bin is appended after standard system directories and never shadows real commands"
exit 0
