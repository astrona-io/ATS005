#!/usr/bin/env bash
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
