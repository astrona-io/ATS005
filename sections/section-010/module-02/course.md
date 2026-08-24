# Chapter 2: Group Lifecycle Management

> *A user can be a member of a group in `/etc/group` and still not have that group's access in their current shell — group membership changes don't retroactively apply to already-open sessions.*

Most exam-style tasks that mention groups are really testing account provisioning — which groups a *user* belongs to. A smaller, easy-to-underestimate set of tasks test the groups themselves: creating one with an exact GID, renaming it without disturbing anything it already governs, deleting one safely, and understanding precisely when a membership change actually takes effect. This chapter drills group lifecycle management on its own terms, independent of user creation.

---

## Part I: Creating a Group With an Exact GID

Left to its own devices, `groupadd` assigns the next available GID out of the range defined in `/etc/login.defs` (`GID_MIN`/`GID_MAX`). That's fine when you don't care about the number — but plenty of real tasks (and this one) require a *specific* GID, often because other systems or file ownership records already expect it:

```bash
sudo groupadd -g 5000 datateam
getent group datateam
```

Check `man 8 groupadd`'s `-g` flag — it pins the exact GID instead of letting the system pick. Skip it, and `datateam` gets whatever GID happens to be next free, silently failing any requirement for an exact number. Notice the verification command: `getent group` rather than `grep /etc/group`. `getent` walks the same NSS (Name Service Switch) resolution chain the system itself uses at runtime, which stays correct even if groups are eventually sourced from somewhere other than the local flat file — grepping the file directly only shows you *local* entries.

---

## Part II: Adding Members — `-aG` vs. `-G`, Again

We covered this trap from the user side in Chapter 1; here it is again, because it's exactly as dangerous applied to *existing* users being folded into a *new* group:

```bash
sudo usermod -aG datateam marta
sudo usermod -aG datateam cilla
```

`-aG` (append) preserves each user's existing primary group and every other supplementary group they already had. Drop the `-a`, and plain `-G datateam` **replaces** the entire supplementary list — both users would silently lose membership in everything else they belonged to, with no warning from the tool.

There's a group-focused alternative that does the same job scoped to a single group at a time:

```bash
sudo gpasswd -a marta datateam
```

Check `man 1 gpasswd`'s `-a` flag. Functionally similar to `usermod -aG` for one group — some administrators find it clearer for one-off additions since it can't accidentally touch any other group membership, by construction.

---

## Part III: The Active-Group Trap

Here's a moment that trips up almost everyone the first time: you add a user to a group, then immediately check their membership in an already-open terminal, and the new group is nowhere to be seen.

```bash
id marta
```

Group membership is read from `/etc/group` at **login/session-start time** and cached into that session. A shell that was already running before the change simply never re-reads the group database — it's not that the change failed, it's that nothing has told this particular session to look again. Two ways to prove the change actually worked:

1. Start a genuinely new session (fresh login or SSH connection).
2. Use `newgrp` to start a subshell with the updated membership active immediately:

```bash
sudo -u marta newgrp datateam
```

Check `man 1 newgrp` — it opens a new shell with the named group as that shell's active primary group, without requiring a full logout/login cycle. This is the fast verification path under exam time pressure.

---

## Part IV: Renaming Without Losing Anything

An old group sometimes just needs a new name — same GID, same members, same file ownership resolution, nothing structurally different:

```bash
getent group legacy-ops
sudo groupmod -n platform-ops legacy-ops
getent group platform-ops
```

Check `man 8 groupmod`'s `-n` flag. It changes **only** the name. The GID stays identical, and so does the member list stored in `/etc/group` — every file on disk already owned by that GID continues to resolve correctly under the new name, since Unix file ownership is stored numerically, not by name string. This is meaningfully different from deleting the old group and creating a brand-new one with the same GID: the numeric file ownership would still coincidentally resolve, but the actual `/etc/group` membership list would have to be rebuilt from scratch. `-n` is the clean, non-destructive path for a pure rename.

---

## Part V: Deleting a Group Safely

```bash
getent group temp-audit
sudo groupdel temp-audit
```

Before deleting anything, it's worth confirming the group truly has no footprint left on the filesystem. Check `man 8 groupdel`'s note: it does **not** search the filesystem or reassign orphaned file ownership. If files still carry a deleted group's old GID in their inode metadata, they keep that raw number forever — `ls -l` will show a bare numeric GID instead of a name, and nothing can be legitimately granted access through that now-nonexistent group again.

```bash
sudo find / -xdev -gid 4200 2>/dev/null
```

Substitute the group's actual GID. An empty result means deletion is clean. `groupdel` will also refuse outright if the group is still set as any user's **primary** group — check `man 8 groupdel`'s stated restriction — in which case that user needs `usermod -g othergroup username` first.

---

## Primary Group vs. Full Group List — Why It Matters

It's worth being explicit about a distinction this whole chapter leans on: a user's **primary** group is what new files they create get group-owned by, by default. Their **full** group list — everything `id` reports — determines what they can currently *access*. Adding someone to `datateam` as a supplementary member doesn't change what group their next `touch newfile` gets stamped with; it only changes what shared resources they can now read or write. Keeping these two concepts separate is what prevents a task asking about one from being solved by fiddling with the other.

## Self-Check

1. If you don't pass `-g` to `groupadd`, where does the assigned GID actually come from?
2. `marta` was just added to `datateam`, but her already-open terminal's `id marta` doesn't show it. Is the group misconfigured?
3. Why is `groupmod -n` safer than deleting a group and recreating it under the new name with the same GID?
4. `groupdel` just removed `temp-audit`. What happens to any file on disk that was still owned by `temp-audit`'s GID?
