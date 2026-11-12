#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' 'COMPANY_PROXY=http://proxy.internal:3128' | sudo tee -a /etc/environment
sudo tee /home/candidate/.bash_profile >/dev/null <<'REFERENCE_FILE'
export EDITOR=vim
REFERENCE_FILE
sudo chown candidate:candidate /home/candidate/.bash_profile
