#!/usr/bin/env bash
set -eu

if ! id "candidate" >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash candidate
  echo "candidate:password123" | sudo chpasswd
fi

sudo -u candidate mkdir -p "/home/candidate/work"
sudo -u candidate tee "/home/candidate/work/helper-tool" > /dev/null <<'EOF'
#!/bin/bash
echo "helper-tool from ~/work"
EOF
sudo chmod +x "/home/candidate/work/helper-tool"

# Make sure PATH hasn't already been touched, so the task is unambiguous.
sudo sed -i '/PATH=/d' "/home/candidate/.bash_profile" 2>/dev/null || true
sudo sed -i '/PATH=/d' "/home/candidate/.profile" 2>/dev/null || true

echo "Ready for PATH extension lab."
exit 0
