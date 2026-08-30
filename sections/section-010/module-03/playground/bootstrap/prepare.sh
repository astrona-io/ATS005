#!/usr/bin/env bash
# OS prep for PLAYGROUND — Account Lifecycle: Defaults, Aging & Locking
# Runs once when the environment comes up. Seeds accounts to expire, lock, and
# remove, plus one carrying an authorized SSH key so the "locking the password
# is not locking the account" point can be shown live over loopback SSH.
# There is no task and no grading.
set -euo pipefail

echo "[playground] account-lifecycle: seeding sample accounts..."

# --- contractor3: under investigation; has a real password AND an SSH key ---
if ! id contractor3 >/dev/null 2>&1; then
    useradd -m -s /bin/bash contractor3
    echo 'contractor3:initialpw' | chpasswd
fi
install -d -m 700 -o contractor3 -g contractor3 /home/contractor3/.ssh
if [ ! -f /root/contractor3_key ]; then
    ssh-keygen -t ed25519 -N '' -C 'contractor3 loopback demo' -f /root/contractor3_key
fi
cp /root/contractor3_key.pub /home/contractor3/.ssh/authorized_keys
chown contractor3:contractor3 /home/contractor3/.ssh/authorized_keys
chmod 600 /home/contractor3/.ssh/authorized_keys

# --- contractor1: fully offboarded; home dir + a file OUTSIDE home ----------
if ! id contractor1 >/dev/null 2>&1; then
    useradd -m -s /bin/bash contractor1
fi
echo "handover notes" > /home/contractor1/NOTES.txt
chown contractor1:contractor1 /home/contractor1/NOTES.txt
install -d -m 755 /var/backups/contractor1
echo "old backup owned by contractor1" > /var/backups/contractor1/dump.sql
chown -R contractor1:contractor1 /var/backups/contractor1

# --- make sure sshd is up so the loopback demo works -----------------------
systemctl enable --now ssh 2>/dev/null || systemctl enable --now sshd 2>/dev/null || true

# contractor7 is intentionally NOT created — the reading creates it with useradd.
echo "[playground] ready. Try:  useradd -D   chage -l contractor3   ssh -i /root/contractor3_key contractor3@localhost id"
