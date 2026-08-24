# Question

Solve this question on: `terminal`

Your team lead put you in charge of a full identity-administration sweep. Complete every task below on this single server:

1. **Account relocation:** User `analyst9` is moving to the finance team. Change their primary group to `finance` and their home directory to `/home/accounts/analyst9` — their existing home directory contents must move with them, nothing left behind at the old path.
2. **New-hire provisioning:** Add a new user `newhire9` with groups `finance` and `ops`, home directory `/home/accounts/newhire9`, shell `/bin/bash`. `newhire9` must be able to run `sudo bash /root/rotate-logs.sh` with no password prompt — and only that exact command, nothing broader.
3. **Group lifecycle:** Create a group `billing-team` with GID `6000` exactly, and add both `analyst9` and `newhire9` to it as a supplementary group without disturbing their primary groups. Rename the group `legacy-billing` (GID `7000`) to `archive-billing` without changing its GID or losing its membership list. Delete the genuinely unused group `temp-scratch` entirely.
4. **Investigation lockout:** Account `audit2` is under investigation and must be locked out immediately, without deleting the account or losing its configuration.
5. **Scheduled offboarding:** Account `shortterm3` is a short-term contract that must fully expire (not just the password) in 14 days.
6. **Immediate removal:** Account `leaver5` has already left and must be removed entirely, including their home directory.
