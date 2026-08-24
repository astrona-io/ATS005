# Question

Solve this question on: `app-srv1`

On this server:

1. Change the primary group of user `user1` to `dev` and the home directory to `/home/accounts/user1` (their existing home directory contents must move with them — nothing should be left behind at the old path).
2. Add a new user `user2` with groups `dev` and `op`, home directory `/home/accounts/user2`, shell `/bin/bash`.
3. User `user2` should be able to execute `sudo bash /root/dangerous.sh` without being prompted for the root password — and only that exact command.
