#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# OS prep for PLAYGROUND — Resource Limits With systemd
# Runs once when the environment comes up. Seeds a running service without any
# limits set by the learner (ledger-sync) and a user with a fixed UID (dana).
# Nothing to solve, no grading.
set -euo pipefail

echo "[playground] systemd-limits: seeding a service and a user..."

id dana >/dev/null 2>&1 || useradd -m -u 2010 -s /bin/bash dana

cat > /etc/systemd/system/ledger-sync.service <<'UNIT'
[Unit]
Description=Ledger sync worker (playground)

[Service]
ExecStart=/usr/bin/sleep infinity

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now ledger-sync.service

echo "[playground] ready. Try:  systemctl show ledger-sync -p LimitNOFILE   systemctl show user-2010.slice -p TasksMax"
ASTRONA_STUDENT_SCRIPT
