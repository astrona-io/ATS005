#!/usr/bin/env bash
set -euo pipefail
sudo setfacl -R -m u:vendor-lee:rwx,u:qa-nina:rx /srv/data/atlas
sudo setfacl -d -m u:vendor-lee:rwx,u:qa-nina:rx /srv/data/atlas
limit=$(sudo awk '/ulimit -Sp/{print $NF}' /home/derek/.bashrc)
printf 'derek hard nproc %s
' "$limit" | sudo tee /etc/security/limits.d/derek-nproc.conf
sudo sed -i '/ulimit -Sp/d' /home/derek/.bashrc
sudo tee /etc/security/limits.d/supportstaff-maxlogins.conf >/dev/null <<'REFERENCE_FILE'
@supportstaff hard maxlogins 1
REFERENCE_FILE
