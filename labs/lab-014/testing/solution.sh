#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/sudoers.d/webops >/dev/null <<'REFERENCE_FILE'
Cmnd_Alias SERVICE_CMDS = /usr/bin/systemctl status ssh, /usr/bin/systemctl restart ssh
%webops ALL=(root) NOPASSWD: SERVICE_CMDS
cleo ALL=(root) /usr/bin/journalctl -u ssh
REFERENCE_FILE
sudo chmod 0440 /etc/sudoers.d/webops
sudo visudo -c
