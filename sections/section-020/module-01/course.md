# Access Control Lists — Permissions Beyond Three Buckets

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS005/tree/main/sections/section-020/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-020/module-01/playground
> astrona destroy posix-acl-playground
> ```

Standard Unix permissions have run the operating system for half a century, and for most files they are all you need. But the model has a ceiling built into its design: exactly three buckets — owner, group, and everyone else — each with one set of `rwx` bits. The moment a real project needs "this one outside contractor gets read-write, this one auditor gets read-only, and neither joins the team's group," three buckets run out of room. POSIX Access Control Lists (ACLs) are the extra layer that fixes this — named-user and named-group permission entries that sit *on top of* the traditional bits without replacing them.

> *ACLs extend permissions, they don't replace them — the owner/group/other bits and the mask entry still cap what an ACL entry actually grants.*

## Learning objectives

After this module you can:

- Explain why the owner/group/other model cannot express a per-user exception, and when an ACL beats creating a new group.
- Read a file's full ACL state with `getfacl`, and spot an extended ACL from the `+` in `ls -l`.
- Grant a named user scoped access with `setfacl -m`, using `-R` to cover content that already exists.
- Configure default ACL entries with `setfacl -d` so files created later inherit the access.
- Explain what the `mask` entry caps, and diagnose an entry whose effective permission is lower than it is written.

## Before you start

You should be comfortable with standard `rwx` permissions, the owner / group / other split, `chmod` and `chown`, and running a command as another user with `sudo -u`. No ACL experience needed.

The playground VM already has:

- `/srv/projects/orion` — a shared tree owned by `team-lead:orion-team`, mode `750`, already holding `README.md` and `docs/spec.md`.
- `contractor-jane` and `auditor-tom` — real accounts that are **not** in `orion-team` and must not be added to it.

Open a shell on it with:

```sh
astrona ssh astro-posix-acl-playground
```

Every command block below runs **inside that VM**.

## Where this fits

ACLs are one of three ways to share a directory: group membership, the setgid bit on a directory (so new files inherit the group), and ACLs. Group membership and setgid change *who is in the group*; ACLs leave the group alone and attach exceptions beside it. The other half of this section — PAM resource limits — is unrelated in mechanism but shares a theme: a fix that "looks right" (a new group; a `.bashrc` `ulimit`) but drags a maintenance cost or a silent hole behind it.

## Reading what is already there

`getfacl` (read: *get file ACL*) prints a file's complete access picture. It works even on a file with no extended ACL — it just echoes the standard bits in ACL notation, with `user::`, `group::`, and `other::` lines matching the three traditional buckets. That is not an error; it is `getfacl` saying "everything this file's access boils down to is those three buckets, so far." The fast visual tell for *whether* a file has an extended ACL is the trailing `+` in `ls -l` output: a plain directory shows `drwxr-x---`, one with an ACL shows `drwxr-x---+`. No `+`, no extended ACL.

> [!TIP]
> **Try it — the baseline, before any ACL**
>
> ```sh
> ls -ld /srv/projects/orion
> getfacl /srv/projects/orion
> ```
>
> Expect something like:
>
> ```text
> drwxr-x--- 3 team-lead orion-team 4096 Aug 30 12:00 /srv/projects/orion
> # file: srv/projects/orion
> # owner: team-lead
> # group: orion-team
> user::rwx
> group::r-x
> other::---
> ```
>
> No `+` on the mode string, no `mask::` line in `getfacl` — this tree has only the standard owner/group/other permissions right now.

## Granting access without touching group membership

The **named-user** ACL entry attaches a permission set to one specific user, independent of any group. Its syntax reads left to right: `u:name:perms` (long form `user:name:perms`) — entity type, entity name, permission triad.

```sh
sudo setfacl -R -m u:contractor-jane:rwx /srv/projects/orion
sudo setfacl -R -m u:auditor-tom:rx /srv/projects/orion
```

`setfacl` (read: *set file ACL*) with `-m` (**m**odify) adds or updates an entry. Two details carry the weight here:

- **`-R` (recursive).** Without it, `setfacl -m` touches only the directory entry itself; every file and subdirectory already inside keeps its old permissions. The new entry on the parent does nothing retroactively. `-R` walks the whole tree and stamps the entry onto everything.
- **`rwx`, not `rw-`, on a directory.** On a directory the execute bit means "you may traverse into this" — `cd` into it, or reach a file inside by path. Grant only `rw-` and the user cannot descend into any subdirectory. "Read-write access to a tree" always implies the execute bit at every directory level.

> [!TIP]
> **Try it — add two named users, watch the `+` appear**
>
> ```sh
> sudo setfacl -R -m u:contractor-jane:rwx /srv/projects/orion
> sudo setfacl -R -m u:auditor-tom:rx /srv/projects/orion
> ls -ld /srv/projects/orion
> getfacl /srv/projects/orion
> ```
>
> Expect something like:
>
> ```text
> drwxrwx---+ 3 team-lead orion-team 4096 Aug 30 12:00 /srv/projects/orion
> # file: srv/projects/orion
> # owner: team-lead
> # group: orion-team
> user::rwx
> user:contractor-jane:rwx
> user:auditor-tom:r-x
> group::r-x
> mask::rwx
> other::---
> ```
>
> The `+` is now on the mode string. Two `user:` lines name the grantees; `# owner:` and `# group:` are unchanged. A `mask::` line appeared on its own — the next-but-one section explains it.

## Making it stick — default ACLs

The entries above cover files that exist *now*. A brand-new file created under `/srv/projects/orion` tomorrow starts with **no ACL** — entries are not inherited just because the parent has some. A **default ACL** is a template the kernel consults at file-creation time:

```sh
sudo setfacl -d -m u:contractor-jane:rwx /srv/projects/orion
sudo setfacl -d -m u:auditor-tom:rx /srv/projects/orion
```

`-d` (**d**efault) sets a default entry instead of an access entry. When a file is created, the kernel copies the default onto it as that file's own access ACL; when a subdirectory is created, it gets both an access ACL *and* its own copy of the default, so the chain keeps propagating down.

The two kinds of `setfacl` call are not interchangeable:

| What you ran | What it covers |
| :--- | :--- |
| `setfacl -R -m …` (no `-d`) | Files / subdirectories that already exist |
| `setfacl -d -m …` (with `-d`) | Files / subdirectories created from now on |

Set only the first and the fix expires the moment someone adds a file. Set only the second and everything already in the tree stays inaccessible.

> [!TIP]
> **Try it — a new file inherits the entries with no `setfacl` on it**
>
> ```sh
> sudo setfacl -d -m u:contractor-jane:rwx /srv/projects/orion
> sudo setfacl -d -m u:auditor-tom:rx /srv/projects/orion
> sudo -u contractor-jane touch /srv/projects/orion/new-note.txt
> getfacl /srv/projects/orion/new-note.txt
> ```
>
> Expect something like:
>
> ```text
> # file: srv/projects/orion/new-note.txt
> # owner: contractor-jane
> # group: orion-team
> user::rw-
> user:contractor-jane:rwx			#effective:rw-
> user:auditor-tom:r-x
> group::r-x
> mask::rw-
> other::---
> ```
>
> `setfacl` was never run against `new-note.txt`, yet it already carries both named-user entries — the default ACL applied them at creation. (The `#effective:` note and `mask::rw-` are the mask at work, next.)

## Proving it stayed additive

The requirement was that the owner, the group, and the base mode do not change, and existing `orion-team` members notice no difference. `ls -ld` confirms it: owner still `team-lead`, group still `orion-team`, base digits still `rwxr-x---` — only the `+` is new. ACLs are strictly additive; they never rewrite the traditional fields.

The behavioural proof is a live test — who can actually do what:

> [!TIP]
> **Try it — jane can write, tom cannot**
>
> ```sh
> sudo -u contractor-jane touch /srv/projects/orion/jane-file.txt && echo "jane: wrote OK"
> sudo -u auditor-tom cat /srv/projects/orion/jane-file.txt && echo "tom: read OK"
> sudo -u auditor-tom touch /srv/projects/orion/tom-file.txt
> ```
>
> Expect something like:
>
> ```text
> jane: wrote OK
> (file contents — empty here)
> tom: read OK
> touch: cannot touch '/srv/projects/orion/tom-file.txt': Permission denied
> ```
>
> `contractor-jane` (`rwx`) creates a file; `auditor-tom` (`r-x`) reads it but is denied the write. Neither user is in `orion-team` — the access came entirely from the named-user ACL entries.

## The mask — the entry almost nobody checks

Every extended ACL has a `mask` entry. It **caps the effective permission** of every named-user entry, every named-group entry, and the owning-group entry — but not the file-owner entry or `other`, which stay governed by the standard bits. It is the one place to restrict every extended entry at once.

`setfacl -m` recalculates the mask automatically to the union of all entries' permissions, which is why `mask::rwx` appeared earlier without you setting it. That auto-recalculation is also the trap: if the mask is ever set *explicitly* to something narrower, every named entry is silently capped to it, whatever the entry itself says. An entry reading `rwx` against an `r-x` mask behaves as `r-x`. Modern `getfacl` annotates a capped entry with `#effective:`.

```sh
sudo setfacl -m m::r-x /srv/projects/orion
```

> [!TIP]
> **Try it — narrow the mask and watch entries get capped**
>
> ```sh
> sudo setfacl -m m::r-x /srv/projects/orion
> getfacl /srv/projects/orion
> sudo setfacl -m u:contractor-jane:rwx /srv/projects/orion
> getfacl /srv/projects/orion | grep -E 'mask|contractor-jane'
> ```
>
> Expect something like:
>
> ```text
> user:contractor-jane:rwx			#effective:r-x
> user:auditor-tom:r-x
> mask::r-x
> ...
> user:contractor-jane:rwx
> mask::rwx
> ```
>
> With `mask::r-x`, `contractor-jane`'s `rwx` entry is annotated `#effective:r-x` — she loses write even though the entry says `rwx`. Re-running any `setfacl -m u:…` recalculates the mask back to the union (`rwx`), which clears the cap. If an ACL ever grants less than it reads, check the mask first.

> [!WARNING]
> **Common pitfalls — ACLs**
>
> - `setfacl -m` without `-R` on a populated tree — existing files are untouched. Use `-R` for content that already exists.
> - Only an access ACL, or only a default ACL — you fixed one half. Existing files need `-R -m`; future files need `-d -m`. Most real ACL mistakes are forgetting one.
> - `rw-` on a directory entry — the user cannot traverse into it. Directories need `x` (`rwx` or `r-x`).
> - An entry that "doesn't work" — a narrowed `mask` is capping it. `getfacl` shows `#effective:`; re-run `setfacl -m` on any entry to recalculate the mask.
> - Reaching for a new group instead — every one-off exception becomes a permanent group to track and clean up. That is the cost ACLs exist to avoid.

## Section recap

You can now read an ACL with `getfacl`, spot one from the `+` in `ls -l`, grant a named user scoped access with `setfacl -R -m`, make new files inherit it with `setfacl -d -m`, and explain why a written permission can be capped lower by the `mask`. The owner, group, and base mode never change — ACLs only add.
