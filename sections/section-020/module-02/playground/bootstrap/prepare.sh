#!/usr/bin/env bash
# OS prep for PLAYGROUND — PAM Resource Limits & Concurrent Logins
# Runs once when the environment comes up. Seeds a user whose process limit was
# "fixed" with a .bashrc ulimit line, an operators group, and a long-running
# process owned by that user so prlimit has something to read. Nothing to
# solve, no grading.
set -euo pipefail

echo "[playground] pam-limits: seeding jackie + operators..."

# --- jackie, with the fragile .bashrc hack already in place --------------
if ! id jackie >/dev/null 2>&1; then
    useradd -m -s /bin/bash jackie
    echo 'jackie:brown' | chpasswd
fi
if ! grep -q 'ulimit -Su' /home/jackie/.bashrc 2>/dev/null; then
    printf '\n# added by a coworker to stop runaway forks (fragile: interactive shells only)\nulimit -Su 150\n' \
        >> /home/jackie/.bashrc
fi

# --- operators group with a few members --------------------------------------
getent group operators >/dev/null || groupadd operators
for u in ops-anna ops-ben ops-carl; do
    id "$u" >/dev/null 2>&1 || useradd -m -s /bin/bash "$u"
    usermod -aG operators "$u"
done

# --- a persistent process owned by jackie, for `prlimit --pid` ------------
systemd-run --quiet --unit=jackie-sleeper --uid=jackie /bin/sleep infinity 2>/dev/null || true

# pam_limits.so ships enabled in /etc/pam.d/common-session on this image —
# left as-is so the reading can grep for it.
echo "[playground] ready. Try:  sudo -u jackie -i ulimit -Su   grep pam_limits /etc/pam.d/common-session"
