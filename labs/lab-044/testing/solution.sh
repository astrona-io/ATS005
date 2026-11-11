#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/skel/WELCOME.txt >/dev/null <<'REFERENCE_FILE'
Welcome aboard.
REFERENCE_FILE
sudo pam-auth-update --enable mkhomedir
sudo su - newcomer -c pwd
