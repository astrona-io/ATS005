#!/usr/bin/env bash
set -euo pipefail
sudo mv /etc/systemd/system/ledger-sync.service.d/limits.conf /tmp/limits.conf
sudo systemctl daemon-reload
sudo systemctl restart ledger-sync
