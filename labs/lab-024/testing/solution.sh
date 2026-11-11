#!/usr/bin/env bash
set -euo pipefail
sudo sh -c 'getfacl -R -p /srv/data/ledger > /root/ledger-acl.backup'
sudo /root/strip-acls.sh
sudo setfacl --restore=/root/ledger-acl.backup
sudo setfacl -R -x u:temp-vendor /srv/data/ledger
sudo find /srv/data/ledger -type d -exec setfacl -x d:u:temp-vendor {} +
