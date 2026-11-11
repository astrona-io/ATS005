#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
set -eu

if ! id "candidate" >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash candidate
  echo "candidate:password123" | sudo chpasswd
fi

# Make sure candidate starts from a clean baseline: no proxy leftovers,
# no EDITOR already set, so the graded task is unambiguous.
sudo sed -i '/COMPANY_PROXY/d' /etc/environment 2>/dev/null || true
sudo sed -i '/EDITOR/d' "/home/candidate/.bash_profile" 2>/dev/null || true

echo "Ready for environment profile configuration lab."
exit 0
ASTRONA_STUDENT_SCRIPT
