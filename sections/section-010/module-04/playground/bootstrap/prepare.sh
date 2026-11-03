#!/usr/bin/env bash
# OS prep for PLAYGROUND — Sudoers Drop-ins, Aliases & Group Rules
# Runs once when the environment comes up. Seeds a team group (webops) with two
# members, one user outside the group, and a backup file in /etc/sudoers.d that
# sudo skips because its name contains a dot. Nothing to solve, no grading.
set -euo pipefail

echo "[playground] sudoers: seeding users, group and a skipped backup file..."

getent group webops >/dev/null || groupadd webops
for account in anna ben cleo; do
  id "$account" >/dev/null 2>&1 || useradd -m -s /bin/bash "$account"
done
usermod -aG webops anna
usermod -aG webops ben

# A backup file: the dot in its name makes sudo skip it, so this rule is not live.
echo 'cleo ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/old-ops.bak
chown root:root /etc/sudoers.d/old-ops.bak
chmod 0440 /etc/sudoers.d/old-ops.bak

visudo -c >/dev/null
echo "[playground] ready. Try:  sudo -l -U cleo   sudo visudo -f /etc/sudoers.d/webops"
