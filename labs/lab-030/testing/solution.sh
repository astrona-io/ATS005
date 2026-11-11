#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/profile.d/onboard.sh >/dev/null <<'REFERENCE_FILE'
export ONBOARD_PORTAL="https://portal.internal/onboarding"
REFERENCE_FILE
sudo chmod 0644 /etc/profile.d/onboard.sh
sudo tee /home/candidate/.bash_profile >/dev/null <<'REFERENCE_FILE'
export EDITOR=nano
export PATH="$PATH:$HOME/bin"
REFERENCE_FILE
sudo chown candidate:candidate /home/candidate/.bash_profile
