#!/usr/bin/env bash
# Confirms COMPANY_PROXY is set system-wide via the PAM-parsed /etc/environment
# file (not a per-user dotfile), and is actually visible in a fresh session.

set -u

if [[ ! -f /etc/environment ]]; then
  echo "FAIL: system-wide proxy - /etc/environment does not exist"
  exit 1
fi

if ! grep -Eq '^COMPANY_PROXY=http://proxy\.internal:3128$' /etc/environment; then
  echo "FAIL: system-wide proxy - /etc/environment does not contain a plain COMPANY_PROXY=http://proxy.internal:3128 line"
  exit 1
fi

if grep -q 'export.*COMPANY_PROXY' /etc/environment; then
  echo "FAIL: system-wide proxy - /etc/environment should contain a bare KEY=VALUE line, not an 'export' statement"
  exit 1
fi

if grep -rl 'COMPANY_PROXY' /home/*/.bashrc /home/*/.bash_profile /home/*/.profile 2>/dev/null | grep -q .; then
  echo "FAIL: system-wide proxy - COMPANY_PROXY should not be duplicated into any individual user's dotfiles"
  exit 1
fi

session_env=$(su - candidate -c 'env' 2>/dev/null || true)
if ! echo "$session_env" | grep -q 'COMPANY_PROXY=http://proxy.internal:3128'; then
  echo "FAIL: system-wide proxy - COMPANY_PROXY is not visible in a fresh login session (su - candidate)"
  exit 1
fi

echo "PASS: COMPANY_PROXY is set system-wide via /etc/environment and visible in a fresh session"
exit 0
