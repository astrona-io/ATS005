# Question

Solve this question on: `terminal`

Astronaut, the `webops` team looks after the `ssh` service on this ship, and the captain wants their orders written down in one clean page of the standing orders. One outside crew member, `cleo`, may only read the service log.

The group `webops` has the members `anna` and `ben`. The user `cleo` is not in the group.

1. Create the drop-in file `/etc/sudoers.d/webops`. It must belong to `root:root` and have mode `0440`.
2. In that file, define a command alias named `SERVICE_CMDS` that holds exactly these two commands: `/usr/bin/systemctl status ssh` and `/usr/bin/systemctl restart ssh`.
3. Let every member of the group `webops` run the commands in `SERVICE_CMDS` as `root` with no password.
4. In the same file, let `cleo` run `/usr/bin/journalctl -u ssh` as `root`. She must type her own password for it: do not use `NOPASSWD` on that rule.
5. Nobody may get more than that. No rule may give `ALL` commands to `anna`, `ben` or `cleo`.
6. Every sudoers file on the ship must still pass `visudo -c`.

The grader checks the file's name, owner and mode, the alias, the answers of `sudo -l -U` for the three users, that `anna` and `ben` can run the two commands with `sudo -n` but not `systemctl stop ssh`, that `cleo` is not allowed to run the service commands, and that `visudo -c` succeeds.
