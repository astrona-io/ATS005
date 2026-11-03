# When A Membership Change Takes Effect

Astronaut, putting a new badge on a crew member only counts when they come aboard again. This part shows you the trap that catches almost everyone the first time, how to see the change straight away with `newgrp`, and why the primary group and the full group list do different jobs.

## The active-group trap

You add a user to a group, check their groups in a terminal that is already open, and the new group is not there. The change did not fail. The open session simply never looked again.

### Why an open shell misses the change

The system reads a user's groups from the group database when a session starts, and the session keeps that list. A shell that was already running never reads the group database again. You can see the change in two ways:

1. Start a really new session: a fresh login or a new SSH connection.
2. Use `newgrp` (short for *new group*) to start a subshell with the group active at once.

`newgrp <group>` opens a new shell with that group as the shell's active primary group. No logout is needed, so it is the fast way to check.

### See the change from a fresh look

Add `marta` to `datateam` (if she is already a member, `gpasswd` just says so), check her from outside, and then open a `newgrp` subshell as her:

<!-- astrona:playground:renew -->

```sh
sudo gpasswd -a marta datateam
id marta
getent group datateam
sudo -u marta newgrp datateam
id
exit
```

Expect something like:

```text
uid=1001(marta) ... groups=1001(marta),1010(staff),1011(projectx)
datateam:x:5000:marta
...
uid=1001(marta) gid=5000(datateam) groups=1001(marta),1010(staff),1011(projectx),5000(datateam)
```

`getent group datateam` proves that `marta` *is* a member on disk. A shell that `marta` opened *before* the change would still not show `datateam`. Inside the `newgrp` subshell, `datateam` is even her active primary group (`gid=`). Your own output may list `cilla` as a member too, if you added her earlier.

## Primary group and full group list

Two lists describe a user's groups, and they control different things. Keeping them apart stops you from "solving" a task about one by changing the other.

### What each one controls

A user's **primary** group is the team tag stamped on the files they create, by default. Their **full** group list, everything `id` reports, is what they can currently *reach*. Adding someone to `datateam` as a supplementary member does not change the group their next `touch newfile` gets. It only changes which shared places they can read or write.

> [!TIP]
> When a group change "did not work", check it with `id <user>` or `getent group <group>` from your own shell first. Both read the database fresh. Only then suspect the user's old session.

## Common pitfalls

> [!WARNING]
> - **"The `id` in my open terminal does not show the new group, so it failed."** It did not fail. That shell kept the groups it started with. Check with a new login, `su - <user>`, or `newgrp`.
> - **Expecting `newgrp` to change the user's login session.** It only affects the subshell it starts. Close it with `exit` and you are back to the original groups.
> - **Changing the primary group when the task asks for access.** Access comes from the full list. Add a supplementary group with `-aG` and leave the primary group alone.
