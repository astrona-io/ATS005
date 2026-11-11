#!/usr/bin/env bash
set -euo pipefail
sudo mv /tmp/limits.conf /etc/systemd/system/ledger-sync.service.d/limits.conf
sudo systemctl daemon-reload
sudo systemctl restart ledger-sync
