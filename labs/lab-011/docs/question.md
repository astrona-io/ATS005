# Question

Solve this question on: `app-srv1`

Astronaut, this ship's crew roster needs three fixes. One crew member must move to a new team and new quarters, a new crew member must come aboard, and that new crew member needs the captain's authority for exactly one order.

1. Change the primary group of user `user1` to `dev` and the home directory to `/home/accounts/user1`. The contents of the existing home directory must move with them; nothing may be left behind at the old path.
2. Add a new user `user2` with the groups `dev` and `op`, the home directory `/home/accounts/user2` and the shell `/bin/bash`.
3. User `user2` must be able to run `sudo bash /root/dangerous.sh` without being asked for a password, and only that exact command.

The grader checks `user1`'s primary group, home path and moved files, `user2`'s groups, home and shell, and that `user2` can run that one command with `sudo -n` while no blanket `NOPASSWD: ALL` rule exists.
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-01](../../../sections/section-010/module-01/course.md).

The grader checks:

- Confirms user1's primary group is dev, home is /home/accounts/user1, and original files were moved (not left behind).
- Confirms user2 exists with groups dev+op, home /home/accounts/user2, and shell /bin/bash.
- Confirms user2 can run 'sudo bash /root/dangerous.sh' with no password prompt, and that the rule is scoped (not a blanket ALL grant).

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
