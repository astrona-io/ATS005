#!/usr/bin/env bash
# OS prep for PLAYGROUND — System-Wide & Personal Environment Profiles
# Runs once when the environment comes up. Seeds two ordinary users, a cron job
# that records its own environment, and a systemd probe unit that records its
# environment — so the reader can see exactly which sessions read which files.
# Nothing to solve, no grading.
set -euo pipefail

echo "[playground] env-profiles: seeding users + env probes..."

# --- two ordinary users ---------------------------------------------------
for u in candidate otheruser; do
    id "$u" >/dev/null 2>&1 || useradd -m -s /bin/bash "$u"
done

# --- a cron job that dumps its environment every minute ------------------
cat > /etc/cron.d/env-probe <<'EOF'
# records what a cron job actually sees in its environment
* * * * * candidate /usr/bin/env > /home/candidate/cron-env.txt 2>&1
EOF
chmod 644 /etc/cron.d/env-probe

# --- a systemd unit that dumps its environment on demand ----------------
cat > /etc/systemd/system/env-probe.service <<'EOF'
[Unit]
Description=Record the environment a systemd service sees

[Service]
Type=oneshot
ExecStart=/bin/sh -c '/usr/bin/env > /run/env-probe.txt'
EOF
systemctl daemon-reload
systemctl start env-probe.service 2>/dev/null || true

# /etc/environment, /etc/profile.d/, and every dotfile are left pristine for
# the reader to edit.
echo "[playground] ready. Try:  cat /etc/environment   su - candidate -c 'echo \$PATH'   cat /home/candidate/cron-env.txt"
