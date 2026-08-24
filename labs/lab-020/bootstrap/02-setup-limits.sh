#!/usr/bin/env bash
set -eu

SOFT_NPROC=120

id derek >/dev/null 2>&1 || sudo useradd -m -s /bin/bash derek
echo "derek:brown" | sudo chpasswd

if ! grep -q "ulimit -Sp" /home/derek/.bashrc 2>/dev/null; then
  echo "ulimit -Sp ${SOFT_NPROC}" | sudo tee -a /home/derek/.bashrc > /dev/null
fi
sudo chown derek:derek /home/derek/.bashrc

sudo groupadd -f supportstaff

sudo mkdir -p /var/lib/lab-020
echo "${SOFT_NPROC}" | sudo tee /var/lib/lab-020/original-soft-nproc > /dev/null

exit 0
