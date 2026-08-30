#!/usr/bin/env bash
# OS prep for PLAYGROUND — POSIX Access Control Lists
# Runs once when the environment comes up. Seeds a shared project tree owned by
# a team lead and a group, plus two users who are NOT in that group, so you can
# practise granting scoped access with setfacl and default ACLs. Nothing to
# solve, no grading.
set -euo pipefail

echo "[playground] posix-acl: seeding shared project tree..."

# --- owning identity -------------------------------------------------------
getent group orion-team >/dev/null || groupadd orion-team
id team-lead >/dev/null 2>&1 || useradd -m -s /bin/bash -g orion-team team-lead

# --- two outside users: deliberately NOT members of orion-team ------------
id contractor-jane >/dev/null 2>&1 || useradd -m -s /bin/bash contractor-jane
id auditor-tom     >/dev/null 2>&1 || useradd -m -s /bin/bash auditor-tom

# --- the shared tree, standard 750, with content that already exists -----
install -d -o team-lead -g orion-team -m 750 /srv/projects/orion
install -d -o team-lead -g orion-team -m 750 /srv/projects/orion/docs
echo "orion design notes"  > /srv/projects/orion/README.md
echo "existing spec"       > /srv/projects/orion/docs/spec.md
chown -R team-lead:orion-team /srv/projects/orion
chmod 640 /srv/projects/orion/README.md /srv/projects/orion/docs/spec.md

# ext4/xfs on this image carry ACL support by default — nothing to enable.
echo "[playground] ready. Try:  getfacl /srv/projects/orion   setfacl -R -m u:contractor-jane:rwx /srv/projects/orion"
