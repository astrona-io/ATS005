#!/usr/bin/env bash
# Starting state for lab-014: group webops with members anna and ben, and the
# user cleo outside the group. No sudo rules are written; that is the task.
set -eu

getent group webops >/dev/null || groupadd webops
for account in anna ben cleo; do
  id "$account" >/dev/null 2>&1 || useradd -m -s /bin/bash "$account"
done
usermod -aG webops anna
usermod -aG webops ben

exit 0
