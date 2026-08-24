#!/usr/bin/env bash
set -eu

SOFT_NPROC=175

id jackie >/dev/null 2>&1 || sudo useradd -m -s /bin/bash jackie
echo "jackie:brown" | sudo chpasswd

if ! grep -q "ulimit -Sp" /home/jackie/.bashrc 2>/dev/null; then
  echo "ulimit -Sp ${SOFT_NPROC}" | sudo tee -a /home/jackie/.bashrc > /dev/null
fi
sudo chown jackie:jackie /home/jackie/.bashrc

sudo groupadd -f operators

# Marker of the originally-planted soft limit, so validation can confirm the
# student's hard limit matches it without re-parsing a .bashrc line the
# student is expected to delete as part of the fix.
sudo mkdir -p /var/lib/lab-022
echo "${SOFT_NPROC}" | sudo tee /var/lib/lab-022/original-soft-nproc > /dev/null

exit 0
