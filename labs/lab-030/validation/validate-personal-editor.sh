#!/usr/bin/env bash
# Confirms EDITOR=nano is set only in candidate's own login-shell profile.

set -u

candidate_home="/home/candidate"
found_in=""

for f in "$candidate_home/.bash_profile" "$candidate_home/.bash_login" "$candidate_home/.profile"; do
  if [[ -f "$f" ]] && grep -Eq "EDITOR=['\"]?nano['\"]?" "$f"; then
    found_in="$f"
    break
  fi
done

if [[ -z "$found_in" ]]; then
  echo "FAIL: personal editor - EDITOR=nano was not found in candidate's login-shell profile"
  exit 1
fi

if ! grep -q 'export' "$found_in"; then
  echo "FAIL: personal editor - $found_in sets EDITOR but never exports it"
  exit 1
fi

value=$(su - candidate -c 'echo $EDITOR' 2>/dev/null || true)
if [[ "$value" != "nano" ]]; then
  echo "FAIL: personal editor - EDITOR is not 'nano' in a fresh candidate login session (got '$value')"
  exit 1
fi

for home in /root /home/*; do
  [[ "$home" == "$candidate_home" ]] && continue
  for f in "$home/.bash_profile" "$home/.bash_login" "$home/.profile" "$home/.bashrc"; do
    if [[ -f "$f" ]] && grep -q 'EDITOR=' "$f"; then
      echo "FAIL: personal editor - EDITOR was also set in $f, but this should be candidate-only"
      exit 1
    fi
  done
done

echo "PASS: EDITOR=nano is set and exported only in candidate's own profile ($found_in)"
exit 0
