#!/usr/bin/env bash
set -eu

if ! command -v setfacl >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y acl
fi

sudo groupadd -f orion-team
id team-lead >/dev/null 2>&1 || sudo useradd -m -g orion-team -s /bin/bash team-lead
id contractor-jane >/dev/null 2>&1 || sudo useradd -m -s /bin/bash contractor-jane
id auditor-tom >/dev/null 2>&1 || sudo useradd -m -s /bin/bash auditor-tom

sudo mkdir -p /srv/projects/orion/reports
sudo tee /srv/projects/orion/README.txt > /dev/null <<'EOF'
Orion project shared workspace.
EOF
sudo tee /srv/projects/orion/reports/q1.txt > /dev/null <<'EOF'
Q1 report placeholder.
EOF

sudo chown -R team-lead:orion-team /srv/projects/orion
sudo chmod -R 750 /srv/projects/orion

exit 0
