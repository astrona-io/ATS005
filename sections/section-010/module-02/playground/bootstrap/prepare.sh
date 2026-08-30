#!/usr/bin/env bash
# OS prep for PLAYGROUND — Group Lifecycle Management
# Runs once when the environment comes up. Seeds sample users and groups so you
# can practise creating a group with a pinned GID, adding members without
# clobbering their other memberships, renaming a group, and deleting one
# cleanly. There is no task and no grading.
set -euo pipefail

echo "[playground] group-lifecycle: seeding sample users and groups..."

# --- sample users, each already in a couple of groups ----------------------
for u in marta cilla; do
    id "$u" >/dev/null 2>&1 || useradd -m -s /bin/bash "$u"
done
getent group staff    >/dev/null || groupadd staff
getent group projectx >/dev/null || groupadd projectx
usermod -aG staff,projectx marta
usermod -aG staff cilla

# --- a legacy group to rename, with a fixed GID and a member ---------------
getent group legacy-ops >/dev/null || groupadd -g 4200 legacy-ops
usermod -aG legacy-ops cilla

# Files on disk owned by that GID, so a rename can be shown to keep resolving.
mkdir -p /srv/legacy-ops
chgrp -R 4200 /srv/legacy-ops
chmod -R 2775 /srv/legacy-ops
echo "owned by GID 4200" > /srv/legacy-ops/README

# --- an unused group to delete -------------------------------------------------
getent group temp-audit >/dev/null || groupadd -g 4300 temp-audit

# GID 5000 is intentionally left FREE for the pinned-GID exercise.
echo "[playground] ready. Try:  getent group legacy-ops   id marta   groupadd -g 5000 datateam"
