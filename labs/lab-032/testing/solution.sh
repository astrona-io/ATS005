#!/usr/bin/env bash
set -euo pipefail
sudo tee /home/candidate/.bash_profile >/dev/null <<'REFERENCE_FILE'
export PATH="$PATH:$HOME/work"
REFERENCE_FILE
sudo chown candidate:candidate /home/candidate/.bash_profile
