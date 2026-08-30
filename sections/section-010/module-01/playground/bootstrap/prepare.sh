#!/usr/bin/env bash
# OS prep for PLAYGROUND — User & Group Account Management
# Runs once when the environment comes up. Seeds a realistic "before" state so
# you can practise relocating an account, provisioning a new one, and writing a
# scoped sudoers rule. There is no task and no grading — poke at it freely.
set -euo pipefail

echo "[playground] user-group-mgmt: seeding sample identity state..."

# --- groups the module talks about --------------------------------------------
getent group dev  >/dev/null || groupadd dev
getent group op   >/dev/null || groupadd op
getent group web  >/dev/null || groupadd web

# --- an existing account set up "wrong" --------------------------------------
# user1: primary group is its own private group, home is the default /home/user1.
# The reading walks through moving both. A marker file lets you prove whether
# `usermod -m` actually moved the contents.
if ! id user1 >/dev/null 2>&1; then
    useradd -m -s /bin/bash user1
    usermod -aG web user1
    echo "this file lived at /home/user1 before any relocation" \
        > /home/user1/ORIGINAL-HOME-MARKER.txt
    chown user1:user1 /home/user1/ORIGINAL-HOME-MARKER.txt
fi

# Parent for the relocated home path does NOT exist yet on purpose — the
# reading covers why `usermod -m -d` fails without it.
rmdir /home/accounts 2>/dev/null || true

# --- a root-owned script for the scoped-sudo section ------------------------
if [ ! -f /root/dangerous.sh ]; then
    cat > /root/dangerous.sh <<'EOF'
#!/usr/bin/env bash
echo "dangerous.sh ran as $(id -un) at $(date -Is)"
EOF
    chmod 0700 /root/dangerous.sh
fi

echo "[playground] ready. Try:  id user1   getent passwd user1   sudo -l -U user1"
