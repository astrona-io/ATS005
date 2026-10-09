# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module was about the life of a crew team: creating it with the right number, adding members safely, renaming it and disbanding it.

**From [Creating Groups And Adding Members](./course-01-creating-groups-and-adding-members.md):**

- `groupadd -g 5000 datateam` pins the GID. Without `-g`, `groupadd` takes the next free number from `/etc/login.defs`.
- `getent group <name>` checks a group the way the system does, from every source it trusts.
- `usermod -aG <group> <user>` and `gpasswd -a <user> <group>` add a member and keep their other groups.

**From [When A Membership Change Takes Effect](./course-02-when-membership-takes-effect.md):**

- A session keeps the group list it started with. A shell that was already open does not see a new group.
- Check with `id <user>`, a fresh login, `su - <user>`, or `newgrp <group>`.
- The primary group decides the group on new files. The full list decides what the user can reach.

**From [Renaming And Deleting Groups](./course-03-renaming-and-deleting-groups.md):**

- `groupmod -n <new> <old>` changes only the name. The GID, the members and the file ownership stay.
- `groupdel` does not touch files. Check with `find / -xdev -gid <GID>` first, and confirm the delete with `getent`.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Group Creation, Membership & the Active-Group Trap Lab](../../../labs/lab-012/docs/question.md) | Renaming And Deleting Groups | created `datateam` with GID `5000` for two users, renamed `legacy-ops` with its GID and members, and deleted `temp-audit` |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. You run <code>groupadd datateam</code> without <code>-g</code>. Which GID does it get?</summary>

The next free GID in the range set by `GID_MIN` and `GID_MAX` in `/etc/login.defs`.
</details>

<details>
<summary>2. Why check a group with <code>getent group</code> instead of <code>grep</code> on <code>/etc/group</code>?</summary>

`getent` follows the system's real lookup chain, so it also finds groups from other sources such as a central directory. `grep` only reads the local file.
</details>

<details>
<summary>3. You added <code>marta</code> to <code>datateam</code>, but <code>id</code> in her open terminal does not show it. Did the change fail?</summary>

No. Her shell kept the group list it started with. A new login, `su - marta` or `newgrp datateam` shows the new group.
</details>

<details>
<summary>4. After <code>groupmod -n platform-ops legacy-ops</code>, what happens to the files owned by GID 4200?</summary>

Nothing changes on disk. Linux stores the number `4200`, so `ls -l` simply shows the new name `platform-ops`.
</details>

<details>
<summary>5. What happens to files still owned by a group's GID after <code>groupdel</code>?</summary>

They keep the bare GID number. `ls -l` shows the number instead of a name, and nobody can get access through that group any more.
</details>

<details>
<summary>6. Does adding a user to a supplementary group change the group on the files they create next?</summary>

No. New files get the user's primary group. A supplementary group only changes what the user can reach.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy group-lifecycle-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-012
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-010/module-02/playground`. It always starts clean, so nothing you broke carries over.

> *Pin the number with `-g`, add with `-aG`, rename with `-n`, and look for a footprint before you delete.*
