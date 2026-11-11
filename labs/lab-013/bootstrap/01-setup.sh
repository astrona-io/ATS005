#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Prepares contractor3 (active) and contractor1 (offboarded, with a home dir marker) for lab-013
set -eu

if ! id contractor3 >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash contractor3
fi
echo "contractor3:temporaryPass1" | sudo chpasswd

if ! id contractor1 >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash contractor1
fi
echo "offboarded contractor notes" | sudo tee /home/contractor1/offboard-notes.txt > /dev/null
sudo chown contractor1:contractor1 /home/contractor1/offboard-notes.txt

echo "Ready for account lifecycle lab."
exit 0
ASTRONA_STUDENT_SCRIPT
