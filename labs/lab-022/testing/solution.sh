#!/usr/bin/env bash
set -euo pipefail
limit=$(sudo awk '/ulimit -Sp/{print $NF}' /home/jackie/.bashrc)
printf 'jackie hard nproc %s
' "$limit" | sudo tee /etc/security/limits.d/jackie-nproc.conf
sudo sed -i '/ulimit -Sp/d' /home/jackie/.bashrc
sudo tee /etc/security/limits.d/operators-maxlogins.conf >/dev/null <<'REFERENCE_FILE'
@operators hard maxlogins 1
REFERENCE_FILE
