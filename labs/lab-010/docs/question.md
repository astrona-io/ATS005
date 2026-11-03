# Question

Solve this question on: `terminal`

Astronaut, mission control has put you in charge of a full sweep of this ship's crew roster. Complete every task below on this one machine:

1. **Account relocation:** User `analyst9` is moving to the finance team. Change their primary group to `finance` and their home directory to `/home/accounts/analyst9`. The contents of the existing home directory must move with them; nothing may be left behind at the old path.
2. **New-hire provisioning:** Add a new user `newhire9` with the groups `finance` and `ops`, the home directory `/home/accounts/newhire9` and the shell `/bin/bash`. `newhire9` must be able to run `sudo bash /root/rotate-logs.sh` without being asked for a password, and only that exact command, nothing broader.
3. **Group lifecycle:** Create the group `billing-team` with GID `6000` exactly, and add both `analyst9` and `newhire9` to it as a supplementary group without disturbing their primary groups. Rename the group `legacy-billing` (GID `7000`) to `archive-billing` without changing its GID or losing its membership list. Delete the unused group `temp-scratch` entirely.
4. **Investigation lockout:** The account `audit2` is under investigation and must be locked out immediately, without deleting the account or losing its configuration.
5. **Scheduled offboarding:** The account `shortterm3` is a short-term contract that must fully expire (not just the password) in 14 days.
6. **Immediate removal:** The account `leaver5` has already left and must be removed entirely, including their home directory.

The grader checks `analyst9`'s primary group, home path and moved files; `newhire9`'s groups, home, shell and its one working `sudo -n` command with no blanket `NOPASSWD: ALL` rule; `billing-team` (GID `6000`, both members), `archive-billing` (GID `7000`, member `billingclerk` kept, `legacy-billing` gone) and the removal of `temp-scratch`; that `audit2` still exists with `passwd -S` status `L`; that `shortterm3` expires in about 14 days; and that `leaver5` and `/home/leaver5` are gone.
