#!/usr/bin/env bash
# OS prep for PLAYGROUND — Extending PATH Safely
# Runs once when the environment comes up. Seeds a user with a personal scripts
# directory holding a genuinely new tool, so the reader can practise appending
# it to PATH and proving a same-named decoy cannot shadow a system command.
# Nothing to solve, no grading.
set -euo pipefail

echo "[playground] safe-path: seeding candidate + ~/work..."

id candidate >/dev/null 2>&1 || useradd -m -s /bin/bash candidate

install -d -o candidate -g candidate -m 755 /home/candidate/work

cat > /home/candidate/work/helper-tool <<'EOF'
#!/bin/bash
echo "helper-tool running from ~/work"
EOF
chmod 0755 /home/candidate/work/helper-tool
chown candidate:candidate /home/candidate/work/helper-tool

# candidate's dotfiles are left as the distro defaults — the reader adds the
# PATH line themselves. No decoy is planted; the reader creates one to test.
echo "[playground] ready. Try:  su - candidate -c 'echo \$PATH'   su - candidate -c 'type helper-tool'"
