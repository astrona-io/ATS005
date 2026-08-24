#!/usr/bin/env bash
set -eu

if ! id "candidate" >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash candidate
  echo "candidate:password123" | sudo chpasswd
fi

sudo -u candidate mkdir -p "/home/candidate/bin"
sudo -u candidate tee "/home/candidate/bin/deploy-helper" > /dev/null <<'EOF'
#!/bin/bash
echo "deploy-helper from ~/bin"
EOF
sudo chmod +x "/home/candidate/bin/deploy-helper"

# Clean baseline: no leftover profile.d drop-ins, no PATH/EDITOR edits yet.
sudo rm -f /etc/profile.d/onboard*.sh
sudo sed -i '/ONBOARD_PORTAL/d' /etc/environment 2>/dev/null || true
sudo sed -i '/EDITOR=/d;/PATH=/d' "/home/candidate/.bash_profile" 2>/dev/null || true
sudo sed -i '/EDITOR=/d;/PATH=/d' "/home/candidate/.profile" 2>/dev/null || true

echo "Ready for the shell environment and PATH capstone lab."
exit 0
