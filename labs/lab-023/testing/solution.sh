#!/usr/bin/env bash
set -euo pipefail
sudo install -d /etc/systemd/system/ledger-sync.service.d /etc/systemd/system/user-2010.slice.d
sudo tee /etc/systemd/system/ledger-sync.service.d/limits.conf >/dev/null <<'REFERENCE_FILE'
[Service]
LimitNOFILE=4096
REFERENCE_FILE
sudo tee /etc/systemd/system/user-2010.slice.d/50-limits.conf >/dev/null <<'REFERENCE_FILE'
[Slice]
TasksMax=100
REFERENCE_FILE
sudo systemctl daemon-reload
sudo systemctl restart ledger-sync
