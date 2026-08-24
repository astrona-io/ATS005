#!/usr/bin/env bash
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
