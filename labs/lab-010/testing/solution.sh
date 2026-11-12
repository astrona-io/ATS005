#!/usr/bin/env bash
set -euo pipefail
sudo groupadd -f finance
sudo groupadd -f ops
sudo mkdir -p /home/accounts
sudo usermod -g finance -d /home/accounts/analyst9 -m analyst9
sudo useradd -m -d /home/accounts/newhire9 -G finance,ops -s /bin/bash newhire9
sudo tee /etc/sudoers.d/newhire9-scoped >/dev/null <<'REFERENCE_FILE'
newhire9 ALL=(root) NOPASSWD: /usr/bin/bash /root/rotate-logs.sh
REFERENCE_FILE
sudo chmod 0440 /etc/sudoers.d/newhire9-scoped
sudo visudo -c
sudo groupadd -g 6000 billing-team
sudo usermod -aG billing-team analyst9
sudo usermod -aG billing-team newhire9
sudo groupmod -n archive-billing legacy-billing
sudo groupdel temp-scratch
sudo passwd -l audit2
sudo chage -E "$(date -d '+14 days' +%F)" shortterm3
sudo userdel -r leaver5
