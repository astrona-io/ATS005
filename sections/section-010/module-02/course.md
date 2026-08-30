# Group Lifecycle Management

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS005/tree/main/sections/section-010/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-010/module-02/playground
> astrona destroy group-lifecycle-playground
> ```

Most tasks that mention groups are really about *users* — which groups an account belongs to. A smaller set is about the groups themselves: creating one with an exact GID, renaming it without disturbing what it governs, deleting one safely, and knowing exactly when a membership change takes effect. This module handles group lifecycle on its own terms, separate from user creation.

> *A user can be a member of a group in `/etc/group` and still not have that group's access in their current shell — membership changes don't reach an already-open session.*

## Learning objectives

After this module you can:

- Create a group with a specific GID using `groupadd -g`, and explain where the GID comes from when you omit it.
- Add existing users to a group with `usermod -aG` or `gpasswd -a` without disturbing their other memberships.
- Explain why a membership change is invisible to an already-open shell, and confirm it with a fresh session or `newgrp`.
- Rename a group with `groupmod -n` and explain why file ownership keeps resolving afterwards.
- Delete a group with `groupdel` after checking that no files on disk still reference its GID.
- Distinguish a user's primary group from their full group list, and say what each one controls.

## Before you start

You should know the primary-group / supplementary-group distinction from Module 1, be able to read `id` output, and have `sudo` available. That is enough.

The playground VM already has:

- Users `marta` (in `staff`, `projectx`) and `cilla` (in `staff`, `legacy-ops`).
- Group `legacy-ops` with GID `4200`, and `/srv/legacy-ops` filled with files group-owned by GID `4200`.
- Group `temp-audit` with GID `4300`, unused, ready to delete.
- GID `5000` deliberately left free.

Open a shell on it with:

```sh
astrona ssh astro-group-lifecycle-playground
```

Every command block below runs **inside that VM**.

## Where this fits

Group lifecycle sits between account provisioning (Module 1) and everything that depends on group-based access — shared directories, the setgid bit, POSIX ACLs in Section 020. Two facts from this module carry forward: file ownership on disk is stored as a *number*, not a name, so renaming a group is safe but deleting one strands any file still carrying its GID; and a group's membership list and a user's *active* groups in a running shell are not the same thing.

## Creating a group with an exact GID

Left alone, `groupadd` (read: *group add*) assigns the next free GID from the range in `/etc/login.defs` (`GID_MIN` / `GID_MAX`). That is fine when the number does not matter. Plenty of real tasks need a *specific* GID, usually because file ownership records or another system already expect it. The `-g` flag pins it:

```sh
sudo groupadd -g 5000 datateam
```

Verify with `getent group`, not `grep /etc/group`. `getent` (read: *get entries*) walks the same NSS (Name Service Switch) lookup chain the system uses at runtime, so it stays correct even when groups come from somewhere other than the local file — LDAP, for instance, in Section 040. Grepping the file only ever shows local entries.

> [!TIP]
> **Try it — pin a GID and read it back**
>
> ```sh
> sudo groupadd -g 5000 datateam
> getent group datateam
> ```
>
> Expect something like:
>
> ```text
> datateam:x:5000:
> ```
>
> The third colon-separated field is the GID — exactly `5000`, not "whatever was next free". The empty fourth field is the member list; nobody is in it yet.

## Adding members — `-aG` vs. `-G`, again

Module 1 met this trap from the user side. It is exactly as dangerous when folding *existing* users into a *new* group:

```sh
sudo usermod -aG datateam marta
sudo usermod -aG datateam cilla
```

`-aG` (append) keeps each user's primary group and every other supplementary group. Drop the `-a` and plain `-G datateam` **replaces** the whole supplementary list — both users would silently lose everything else they were in, with no warning.

There is a group-focused alternative, `gpasswd` (read: *group password* — it manages `/etc/group` and `/etc/gshadow`), scoped to one group at a time:

```sh
sudo gpasswd -a marta datateam
```

`gpasswd -a` does the same job as `usermod -aG` for a single group, and by construction it cannot touch any other group — some administrators prefer it for one-off additions for that reason.

> [!TIP]
> **Try it — add two members two ways, without collateral damage**
>
> ```sh
> id marta
> sudo usermod -aG datateam marta
> sudo gpasswd -a cilla datateam
> id marta
> getent group datateam
> ```
>
> Expect something like:
>
> ```text
> uid=1001(marta) gid=1001(marta) groups=1001(marta),1010(staff),1011(projectx)
> ...
> uid=1001(marta) gid=1001(marta) groups=1001(marta),1010(staff),1011(projectx),5000(datateam)
> datateam:x:5000:marta,cilla
> ```
>
> `datateam` is appended to `marta`'s list; `staff` and `projectx` are still there. The group's own member field now lists both users.

## The active-group trap

Here is what catches almost everyone the first time: you add a user to a group, immediately check their membership in a terminal that is already open, and the new group is not there.

Group membership is read from `/etc/group` at **login / session-start time** and cached into that session. A shell that was already running never re-reads the group database — the change did not fail, nothing has told that session to look again. Two ways to see the change:

1. Start a genuinely new session (fresh login or SSH connection).
2. Use `newgrp` (read: *new group*) to start a subshell with the group active immediately.

`newgrp <group>` opens a new shell with the named group as that shell's active primary group, no logout required — the fast verification path.

> [!TIP]
> **Try it — the change is there, the old shell just cannot see it**
>
> ```sh
> sudo gpasswd -a marta datateam
> id marta
> getent group datateam
> sudo -u marta newgrp datateam
> id
> exit
> ```
>
> Expect something like:
>
> ```text
> uid=1001(marta) ... groups=1001(marta),1010(staff),1011(projectx)
> datateam:x:5000:marta
> ...
> uid=1001(marta) gid=5000(datateam) groups=1001(marta),1010(staff),1011(projectx),5000(datateam)
> ```
>
> `getent group datateam` proves `marta` *is* a member on disk. The first `id marta` — resolved fresh — already shows it, but a shell `marta` had open *before* the change would not. Inside the `newgrp` subshell, `datateam` is even her active primary group (`gid=`).

> [!WARNING]
> **Common pitfalls — membership timing**
>
> - "The `id` in my open terminal doesn't show the new group, so it failed" — it did not. That shell cached its groups at start. Check with a new login, `su - <user>`, or `newgrp`.
> - Expecting `newgrp` to change the user's *login* session — it only affects the subshell it spawns. Close it with `exit` and you are back to the original groups.

## Renaming without losing anything

Sometimes a group just needs a new name — same GID, same members, same file-ownership resolution:

```sh
sudo groupmod -n platform-ops legacy-ops
```

`groupmod` (read: *group modify*) with `-n` (**n**ew name) changes **only** the name. The GID is untouched, and so is the member list in `/etc/group`. Every file already owned by that GID keeps resolving under the new name, because Unix stores file ownership numerically, not as a name string. That makes `-n` meaningfully different from deleting the group and recreating it with the same GID: with the delete-and-recreate route the numeric ownership would still coincidentally resolve, but the membership list would have to be rebuilt by hand.

> [!TIP]
> **Try it — rename, and watch file ownership follow**
>
> ```sh
> getent group legacy-ops
> ls -l /srv/legacy-ops
> sudo groupmod -n platform-ops legacy-ops
> getent group platform-ops
> getent group legacy-ops
> ls -l /srv/legacy-ops
> ```
>
> Expect something like:
>
> ```text
> legacy-ops:x:4200:cilla
> -rw-rw-r-- 1 root legacy-ops 16 Aug 30 12:00 README
> platform-ops:x:4200:cilla
> (no output for legacy-ops)
> -rw-rw-r-- 1 root platform-ops 16 Aug 30 12:00 README
> ```
>
> GID `4200` and member `cilla` are unchanged. The files under `/srv/legacy-ops` never moved — `ls -l` just resolves GID `4200` to its new name.

## Deleting a group safely

```sh
sudo groupdel temp-audit
```

`groupdel` (read: *group delete*) removes the group from `/etc/group` and `/etc/gshadow`. It does **not** search the filesystem or reassign orphaned ownership. Any file still carrying the deleted GID keeps that raw number forever — `ls -l` then shows a bare numeric GID instead of a name, and nothing can be granted access through that now-nonexistent group again. So check for a footprint first:

```sh
sudo find / -xdev -gid 4300 2>/dev/null
```

`-xdev` keeps `find` on one filesystem (it will not descend into other mounts); an empty result means the deletion is clean. `groupdel` also refuses outright if the group is any user's **primary** group — that user needs `usermod -g <other> <user>` first.

> [!TIP]
> **Try it — confirm no footprint, then delete**
>
> ```sh
> sudo find / -xdev -gid 4300 2>/dev/null
> getent group temp-audit
> sudo groupdel temp-audit
> getent group temp-audit; echo "exit status: $?"
> ```
>
> Expect something like:
>
> ```text
> temp-audit:x:4300:
> exit status: 2
> ```
>
> `find` prints nothing — GID `4300` owns no files, so the delete is safe. After `groupdel`, `getent` finds nothing and exits non-zero (`2` = name not found), which is how you confirm the group is gone.

## Primary group vs. full group list — why it stays separate

This module leans on one distinction worth stating plainly. A user's **primary** group is what their newly created files are group-owned by, by default. Their **full** group list — everything `id` reports — is what they can currently *access*. Adding someone to `datateam` as a supplementary member does not change what group their next `touch newfile` is stamped with; it only changes which shared resources they can read or write. Keeping the two apart is what stops a task about one from being "solved" by changing the other.
