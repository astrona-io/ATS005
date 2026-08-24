#!/usr/bin/env bash
# Confirms ~/work was appended (not prepended) to candidate's PATH, persisted
# in a login-shell dotfile so it survives a fresh session.

set -u

effective_path=$(su - candidate -c 'echo $PATH' 2>/dev/null || true)

if [[ -z "$effective_path" ]]; then
  echo "FAIL: PATH extension - could not read candidate's effective PATH from a fresh login shell"
  exit 1
fi

work_index=-1
usrbin_index=-1
i=0
IFS=':' read -ra dirs <<< "$effective_path"
for d in "${dirs[@]}"; do
  if [[ "$d" == "/home/candidate/work" ]]; then
    work_index=$i
  fi
  if [[ "$d" == "/usr/bin" ]]; then
    usrbin_index=$i
  fi
  i=$((i + 1))
done

if [[ "$work_index" -eq -1 ]]; then
  echo "FAIL: PATH extension - /home/candidate/work is not present in candidate's PATH in a fresh login session"
  exit 1
fi

if [[ "$usrbin_index" -eq -1 ]]; then
  echo "FAIL: PATH extension - /usr/bin not found in candidate's PATH at all, cannot verify ordering"
  exit 1
fi

if [[ "$work_index" -lt "$usrbin_index" ]]; then
  echo "FAIL: PATH extension - ~/work appears BEFORE /usr/bin in PATH, meaning it was prepended, not appended"
  exit 1
fi

if ! su - candidate -c 'command -v helper-tool' >/dev/null 2>&1; then
  echo "FAIL: PATH extension - helper-tool in ~/work is not runnable by name from a fresh login shell"
  exit 1
fi

echo "PASS: ~/work is appended after standard system directories in candidate's persisted PATH"
exit 0
