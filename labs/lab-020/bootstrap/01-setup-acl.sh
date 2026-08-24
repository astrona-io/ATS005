#!/usr/bin/env bash
set -eu

if ! command -v setfacl >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y acl
fi

sudo groupadd -f atlas-team
id lead-dev >/dev/null 2>&1 || sudo useradd -m -g atlas-team -s /bin/bash lead-dev
id vendor-lee >/dev/null 2>&1 || sudo useradd -m -s /bin/bash vendor-lee
id qa-nina >/dev/null 2>&1 || sudo useradd -m -s /bin/bash qa-nina

sudo mkdir -p /srv/data/atlas/exports
sudo tee /srv/data/atlas/README.txt > /dev/null <<'EOF'
Atlas project shared workspace.
EOF
sudo tee /srv/data/atlas/exports/summary.txt > /dev/null <<'EOF'
Export summary placeholder.
EOF

sudo chown -R lead-dev:atlas-team /srv/data/atlas
sudo chmod -R 750 /srv/data/atlas

exit 0
