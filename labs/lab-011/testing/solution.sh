#!/usr/bin/env bash
set -euo pipefail
sudo groupadd -f dev
sudo groupadd -f op
sudo mkdir -p /home/accounts
sudo usermod -g dev -d /home/accounts/user1 -m user1
sudo useradd -m -d /home/accounts/user2 -G dev,op -s /bin/bash user2
sudo tee /etc/sudoers.d/user2-scoped >/dev/null <<'REFERENCE_FILE'
user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh
REFERENCE_FILE
sudo chmod 0440 /etc/sudoers.d/user2-scoped
sudo visudo -c
