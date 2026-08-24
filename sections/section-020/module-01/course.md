# Chapter 1: Access Control Lists — Permissions Beyond Three Buckets

Standard Unix permissions have carried the operating system for half a century, and for most files they are all you will ever need. But the model has a hard ceiling built into its design: exactly three buckets — owner, group, and everyone else — each with a single set of `rwx` bits. The moment a real project needs "this one outside contractor gets read-write, this one auditor gets read-only, but neither of them joins the team's actual group," the three-bucket model runs out of room.

In this chapter we solve that problem the way the exam expects: with POSIX Access Control Lists, a layer of extra permission entries that sits on top of the traditional owner/group/other bits without replacing or rewriting them.

> *ACLs extend permissions, they don't replace them — the standard owner/group/other bits and the mask entry still cap what an ACL entry can actually grant.*

---

## The Problem With Three Buckets

Picture a shared project directory, `/srv/projects/orion`, owned by `team-lead:orion-team` with permissions `750` — the owner can do anything, the group can read and enter, and everyone else is locked out entirely.

Now a contractor shows up who needs read-write access to that directory tree, but who absolutely should not become a member of `orion-team` — doing so would hand her access to every *other* resource that group can touch, which is far more than the task intends. An auditor needs the mirror image: read-only access, also without joining the group.

The tempting shortcut — "just make a new group for this" — technically works, but it spirals. Every one-off exception becomes a permanent group that has to be tracked, audited, and eventually cleaned up. ACLs exist so you never have to make that trade.

---

## Part I: Reading What's Already There

Before changing anything, inspect the baseline:

```bash
ls -ld /srv/projects/orion
getfacl /srv/projects/orion
```

`ls -ld` shows you the owner, group, and mode digits you'd expect from any directory. Watch the very end of the permission string closely — on a plain directory with no ACL, there is nothing after the final `-` or `x`. Once an ACL is attached, a trailing `+` appears (`drwxr-x---+`), and that single character is your fastest sanity check under time pressure: no `+`, no extended ACL, full stop.

`getfacl` works even on a file that has no extended ACL at all — it simply echoes the standard bits back to you in ACL notation:

```text
# file: srv/projects/orion
# owner: team-lead
# group: orion-team
user::rwx
group::r-x
other::---
```

This is not an error. It is `getfacl` telling you, honestly, "here is everything this file's access currently boils down to," which happens to be nothing more than the traditional three buckets so far.

Before relying on ACLs at all, confirm the filesystem underneath actually supports them:

```bash
mount | grep " / "
```

On ext4 and XFS with a reasonably modern kernel, ACL support is compiled in and effectively always on, whether or not `acl` explicitly appears in the mount options list. If it genuinely is disabled, the very first `setfacl` you run will fail outright with an "Operation not supported" error — which is itself the diagnostic, so don't panic if you see it; remount with `-o remount,acl` and move on.

---

## Part II: Granting Access Without Touching Group Membership

The named-user ACL entry is the tool for this exact job — it attaches a permission set to one specific user, independent of any group:

```bash
sudo setfacl -R -m u:contractor-jane:rwx /srv/projects/orion
sudo setfacl -R -m u:auditor-tom:rx /srv/projects/orion
```

Two details matter enormously here, and both are easy to skip past under exam pressure.

**The `-R` flag.** Without it, `setfacl -m` only touches the directory entry itself. Every file and subdirectory *already* inside the tree keeps its old permissions completely unchanged — the new ACL entry on the parent directory does nothing retroactively for existing content. `-R` walks the entire tree and stamps the same entry onto everything it finds. If contractor-jane needs access to files that already exist, `-R` is not optional.

**Why `rwx` and not `rw-` for a directory.** This trips up almost everyone the first time. On a directory, the execute bit doesn't mean "run this as a program" — it means "you may traverse into this directory," i.e., `cd` into it or open a file inside it by path. Grant `contractor-jane` only `rw-` on a directory and she can list its contents and even create files at the top level in some configurations, but she cannot descend into any subdirectory to reach a file by path. "Read-write access to a tree" always implies the execute bit at every directory level in that tree.

The entry syntax itself — `u:name:perms` (the long form is `user:name:perms`) — reads left to right exactly like it sounds: entity type, entity name, permission triad.

---

## Part III: Making It Stick — Default ACLs

Steps so far only solved half the problem. They granted access to files that exist *right now*. Tomorrow, when someone on the team creates a brand-new file under `/srv/projects/orion`, that file starts life with **no ACL at all** — access entries are not inherited automatically just because the parent directory happens to have some.

This is what **default ACLs** are for:

```bash
sudo setfacl -d -m u:contractor-jane:rwx /srv/projects/orion
sudo setfacl -d -m u:auditor-tom:rx /srv/projects/orion
```

The `-d` flag sets a *default* ACL entry rather than an access ACL entry. A default ACL is a template — the kernel consults it at file-creation time and copies it onto the new file (as that file's own access ACL) or new subdirectory (as both an access ACL *and* a fresh default ACL of its own, so the inheritance chain keeps propagating downward).

Notice that this section's two `setfacl` calls and Part II's two `setfacl -R` calls are not interchangeable — they solve two different halves of the same requirement:

| What you ran | What it covers |
| :--- | :--- |
| `setfacl -R -m ...` (no `-d`) | Files/subdirectories that already exist |
| `setfacl -d -m ...` (with `-d`) | Files/subdirectories created from now on |

Set only the first and the fix silently expires the moment anyone adds a new file. Set only the second and every file already in the tree stays inaccessible. A task that says "new files should not need a manual `setfacl` run every time" is testing specifically for the second half.

---

## Part IV: The Mask — The Entry Almost Nobody Checks

Run `getfacl` again after the steps above and you'll see one more line you haven't touched directly:

```text
mask::rwx
```

The **mask** entry caps the *effective* permission of every named user entry and named group entry (and the traditional owning-group entry) in the ACL — but conspicuously not the file-owner entry or the "other" entry, which remain governed purely by the standard bits. Its entire purpose is to give you one place to instantly restrict every extended ACL entry at once, without hand-editing each named entry individually — useful for a security sweep across a file with a dozen different grantees.

`setfacl -m` automatically recalculates the mask to the union of all entries' permissions by default, which is why the mask already shows `rwx` here without you setting it explicitly. But this auto-recalculation is exactly what makes the mask dangerous to overlook: if you (or a script, or a previous administrator) ever set the mask explicitly to something narrower —

```bash
sudo setfacl -m m::rwx /srv/projects/orion
```

— then every named entry gets silently capped to whatever the mask allows, *regardless of what the entry itself says*. An entry that reads `rwx` against a `r-x` mask effectively behaves as `r-x`. If an ACL entry ever looks like it grants more than what's actually enforced, the mask is the very first thing to check — modern `getfacl` output even annotates a capped entry directly with an `#effective:` comment.

---

## Part V: Proving It Didn't Change What It Shouldn't

The task's constraints were explicit: neither the owner nor the group changes, and existing members of `orion-team` see no difference in their own access. Confirm this directly:

```bash
ls -ld /srv/projects/orion
```

Expected: owner and group still read `team-lead` and `orion-team`, the base mode digits (`rwxr-x---`) are exactly as they were — only the trailing `+` is new. This is the core guarantee of ACLs as a mechanism: they are strictly additive. They never rewrite the traditional owner, group, or base permission fields; they attach alongside them.

The full proof of the fix is a live test, not just reading `getfacl` output:

```bash
sudo -u contractor-jane touch /srv/projects/orion/test-write.txt
sudo -u auditor-tom cat /srv/projects/orion/test-write.txt
sudo -u auditor-tom touch /srv/projects/orion/should-fail.txt
getfacl /srv/projects/orion/test-write.txt
```

The last command is the one that actually proves default-ACL inheritance works: `test-write.txt` was created moments ago by contractor-jane, and it should already carry both named-user entries — `user:contractor-jane:rwx` and `user:auditor-tom:r-x` — even though `setfacl` was never run against that file directly. That's the default ACL from Part III doing its job silently, at the exact moment the file was created.

---

## Chapter Summary

- Standard `rwx` permissions give you exactly three buckets (owner/group/other); ACLs add named-user and named-group entries on top, without touching who owns the file or who's in which group.
- `getfacl` reads the full ACL state; `setfacl -m` adds or updates an entry; `-R` applies a change recursively to an existing tree; `-d` sets a *default* entry that new files/subdirectories inherit automatically going forward.
- Directories need the execute bit in an ACL entry to be traversable — `rwx`, not `rw-`, for "full access to a tree."
- The mask entry caps the effective permission of every named entry; check it whenever an ACL doesn't seem to behave as granted.
- A trailing `+` in `ls -l` output is the fast visual tell that a file carries an extended ACL — check it before reaching for `getfacl`.
- Access ACLs (what exists now) and default ACLs (what will exist later) are two different fixes for two different halves of the same requirement — most real-world ACL mistakes are forgetting one of the two.

## Self-Check

1. Why does adding a contractor to the project's group solve the *access* problem but violate the actual requirement in most real tasks?
2. You set `u:auditor-tom:rwx` on a directory, but `getfacl` shows `mask::r-x`. What does auditor-tom actually get?
3. What's the practical difference between running `setfacl -m` with `-d` versus without it, and why do most real scenarios need both?
