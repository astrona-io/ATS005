#!/usr/bin/env bash
# Confirms contractor7 was created using the system's actual useradd -D defaults
set -u

if ! id contractor7 >/dev/null 2>&1; then
  echo "FAIL: contractor7 defaults - account does not exist"
  exit 1
fi

default_shell=$(useradd -D | grep '^SHELL=' | cut -d= -f2)
default_home_base=$(useradd -D | grep '^HOME=' | cut -d= -f2)
expected_home="${default_home_base}/contractor7"

actual_shell=$(getent passwd contractor7 | cut -d: -f7)
actual_home=$(getent passwd contractor7 | cut -d: -f6)

if [[ -n "$default_shell" ]] && [[ "$actual_shell" != "$default_shell" ]]; then
  echo "FAIL: contractor7 defaults - shell is '$actual_shell', expected the system default '$default_shell' (no -s override should have been used)"
  exit 1
fi

if [[ "$actual_home" != "$expected_home" ]]; then
  echo "FAIL: contractor7 defaults - home is '$actual_home', expected default base path '$expected_home' (no -d override should have been used)"
  exit 1
fi

if [[ ! -d "$actual_home" ]]; then
  echo "FAIL: contractor7 defaults - home directory '$actual_home' does not exist on disk"
  exit 1
fi

echo "PASS: contractor7 uses the system's real useradd -D defaults for shell and home."
exit 0
