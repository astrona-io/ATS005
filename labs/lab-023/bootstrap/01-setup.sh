#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
sudo -n bash <<'BOOTSTRAP_ROOT'
# Starting state for lab-023: a running service with no limits set and a user
# with the fixed UID 2010. The limits themselves are the task.
set -eu

id dana >/dev/null 2>&1 || useradd -m -u 2010 -s /bin/bash dana

cat > /etc/systemd/system/ledger-sync.service <<'UNIT'
[Unit]
Description=Ledger sync worker

[Service]
ExecStart=/usr/bin/sleep infinity

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now ledger-sync.service

exit 0
BOOTSTRAP_ROOT
ASTRONA_STUDENT_SCRIPT
