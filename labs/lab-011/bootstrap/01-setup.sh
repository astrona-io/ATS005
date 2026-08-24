#!/usr/bin/env bash
# Prepares user1's stale home/group state and the sudo target script for lab-011
set -eu

if ! id user1 >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash user1
fi
sudo mkdir -p "/home/user1"
echo "quarterly-report-draft" | sudo tee /home/user1/important-file.txt > /dev/null
sudo chown -R user1:user1 /home/user1

sudo tee /root/dangerous.sh > /dev/null <<'EOF'
#!/usr/bin/env bash
echo "dangerous script executed as $(whoami)"
EOF
sudo chmod 0700 /root/dangerous.sh
sudo chown root:root /root/dangerous.sh

echo "Ready for user/group provisioning lab."
exit 0
