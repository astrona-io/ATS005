#!/usr/bin/env bash
set -euo pipefail
sudo useradd -m contractor7
printf 'contractor7:Training-only-41!
' | sudo chpasswd
sudo passwd -e contractor7
sudo chage -E "$(date -d '+30 days' +%F)" contractor7
sudo passwd -l contractor3
sudo userdel -r contractor1
