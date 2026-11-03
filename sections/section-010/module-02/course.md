# Group Lifecycle Management

Astronaut, most tasks that mention groups are really about *users*: which teams a crew member belongs to. A smaller set is about the teams themselves. You create a team with an exact number, rename it without disturbing what it controls, delete it safely, and know exactly when a membership change reaches a crew member who is already aboard. This module handles the life of a group on its own terms.

## Learning objectives

After this module you can:

- Create a group with a specific GID using `groupadd -g`, and say where the GID comes from when you leave it out.
- Add existing users to a group with `usermod -aG` or `gpasswd -a` without disturbing their other memberships.
- Explain why a membership change is invisible to a shell that is already open, and confirm it with a fresh session or `newgrp`.
- Rename a group with `groupmod -n`, and explain why file ownership keeps working afterwards.
- Delete a group with `groupdel` after checking that no files on disk still carry its GID.
- Tell a user's primary group from their full group list, and say what each one controls.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **Primary and supplementary groups.** Every user has one primary group (the home team whose tag goes on every new file) and any number of supplementary groups (extra team badges for access).
- **How to read `id` output.** `gid=` is the primary group, and `groups=` is the full list.
- **How to run a command with `sudo`.** `sudo` borrows the captain's authority (the `root` account) for one order.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- The users `marta` (in `staff` and `projectx`) and `cilla` (in `staff` and `legacy-ops`).
- The group `legacy-ops` with GID `4200`, and the directory `/srv/legacy-ops` with files owned by GID `4200`.
- The group `temp-audit` with GID `4300`. Nothing uses it, so it is ready to delete.
- GID `5000` left free on purpose.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh group-lifecycle-playground
```

Every command block in the parts runs **inside that virtual machine**.

## How this module is laid out

1. [Creating Groups And Adding Members](./course-01-creating-groups-and-adding-members.md): `groupadd -g`, checking with `getent`, and adding members with `usermod -aG` or `gpasswd -a`.
2. [When A Membership Change Takes Effect](./course-02-when-membership-takes-effect.md): why an open shell does not see a new group, `newgrp`, and the primary group versus the full list.
3. [Renaming And Deleting Groups](./course-03-renaming-and-deleting-groups.md): `groupmod -n`, and `groupdel` after a check for files that still use the GID.
   - Mission: [Group Creation, Membership & the Active-Group Trap Lab](../../../labs/lab-012/docs/question.md)
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md)

## Why this matters

Shared directories, the setgid bit and access control lists all grant access through groups. Two facts from this module protect all of them. File ownership on disk is stored as a *number*, not a name, so renaming a group is safe but deleting one leaves a bare number on any file that still carries its GID. And a group's member list is not the same as the groups a running shell has active.

> *A user can be a member of a group in `/etc/group` and still not have that group's access in their current shell: membership changes do not reach a session that is already open.*
