# Question

Solve this question on: `terminal`

Astronaut, two things on this ship need a ceiling, and neither one comes through the login airlock. Set the ceilings where the ship's core can see them.

1. The service `ledger-sync` is running and has no limits of its own. Give it an open-file limit (`LimitNOFILE`) of `4096`. The running process must carry the new limit, not just the unit file.
2. The user `dana` (UID `2010`) must never hold more than `100` tasks in her user slice. Set `TasksMax=100` on her slice, and save it so it stays after `systemctl daemon-reload` and after a reboot. A runtime-only change does not count.
3. Do not change `/etc/security/limits.conf` or the files in `/etc/security/limits.d/`. They do not reach services.

The grader checks that `ledger-sync` is active, that `systemctl show` reports `LimitNOFILE=4096`, that the main process shows `4096` for open files in `/proc/<pid>/limits`, that `systemctl show user-2010.slice` reports `TasksMax=100`, and that a saved drop-in file holds the setting.
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-03](../../../sections/section-020/module-03/course.md).

The grader checks:

- Confirms ledger-sync is running with LimitNOFILE=4096 in its unit and on the running process.
- Confirms user-2010.slice has TasksMax=100 and that the setting is saved in a drop-in file.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
