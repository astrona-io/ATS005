# Renaming And Deleting Groups

Astronaut, teams get new names and old teams are disbanded. This part shows you how to rename a group without losing its number or its members, and how to delete a group only after you have checked that no crate in the cargo hold still carries its number.

## Renaming without losing anything

Sometimes a group only needs a new name: the same GID, the same members, and the same files still owned by it. `groupmod` (short for *group modify*) does exactly that.

### Rename, and watch file ownership follow

Read the group and its files, rename it, and read both again:

<!-- astrona:playground:renew -->

```sh
getent group legacy-ops
ls -l /srv/legacy-ops
sudo groupmod -n platform-ops legacy-ops
getent group platform-ops
getent group legacy-ops
ls -l /srv/legacy-ops
```

Expect something like:

```text
legacy-ops:x:4200:cilla
-rw-rw-r-- 1 root legacy-ops 16 Aug 30 12:00 README
platform-ops:x:4200:cilla
(no output for legacy-ops)
-rw-rw-r-- 1 root platform-ops 16 Aug 30 12:00 README
```

GID `4200` and the member `cilla` did not change. The files under `/srv/legacy-ops` never moved: `ls -l` now just shows GID `4200` by its new name.

### Why the files follow the new name

`groupmod -n` (for **n**ew name) changes **only** the name. The GID stays, and so does the member list in `/etc/group`. Every file owned by that GID keeps working under the new name, because Linux stores file ownership as a number, not as a name. So `-n` is better than deleting the group and creating it again with the same GID. The number would still match the files, but you would have to rebuild the member list by hand.

## Deleting a group safely

`groupdel` (short for *group delete*) removes a team from the roster. It does not search the cargo hold, so you check for leftovers first.

### What `groupdel` does and does not do

This is the command. Do not run it yet; the check below comes first.

```sh
sudo groupdel temp-audit
```

`groupdel` removes the group from `/etc/group` and `/etc/gshadow`. It does **not** search the filesystem or change file ownership. Any file that still carries the deleted GID keeps that bare number forever. `ls -l` then shows a number instead of a name, and nobody can get access through that group again. `groupdel` also refuses outright if the group is any user's **primary** group; move that user first with `usermod -g <other> <user>`.

### Look for a footprint first

Search for files that still use the group's GID:

```sh
sudo find / -xdev -gid 4300 2>/dev/null
```

`-xdev` keeps `find` on one filesystem: it does not walk into other mounted disks. An empty result means the delete is clean.

### Confirm no footprint, then delete

Check for files, read the group, delete it, and read it again:

```sh
sudo find / -xdev -gid 4300 2>/dev/null
getent group temp-audit
sudo groupdel temp-audit
getent group temp-audit; echo "exit status: $?"
```

Expect something like:

```text
temp-audit:x:4300:
exit status: 2
```

`find` prints nothing: GID `4300` owns no files, so the delete is safe. After `groupdel`, `getent` finds nothing and exits with `2`, which means "name not found". That is how you confirm the group is gone.

## Common pitfalls

> [!WARNING]
> - **Deleting and re-creating a group to rename it.** You lose the member list. Use `groupmod -n`.
> - **Deleting a group that still owns files.** Those files keep a bare GID number. Run `find / -xdev -gid <GID>` first.
> - **Deleting a user's primary group.** `groupdel` refuses. Give the user another primary group with `usermod -g` first.

## Your mission: Group Creation, Membership & the Active-Group Trap Lab

You can now create a group with an exact GID, add members without losing their other groups, rename a group and delete one safely. Now prove it in a graded mission: create `datateam` with GID `5000` for two users, rename `legacy-ops` without changing its GID or members, and delete an unused group.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop group-lifecycle-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-012
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-012
```

Read the task in [`question.md`](../../../labs/lab-012/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-012
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-012
astrona start group-lifecycle-playground
```
