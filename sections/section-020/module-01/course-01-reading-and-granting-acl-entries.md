# Reading And Granting ACL Entries

Astronaut, before you tape a guest list to a compartment, look at what is already on it. This part shows you how to read a directory's full access picture, and how to add two named users to a whole tree without touching the team's membership.

## Reading what is already there

`getfacl` (short for *get file ACL*) prints a file's complete access picture. It works even on a file with no extended ACL, so it is always the first thing to run.

### See the starting point

Look at the shared tree before any ACL exists:

<!-- astrona:playground:renew -->

```sh
ls -ld /srv/projects/orion
getfacl /srv/projects/orion
```

Expect something like:

```text
drwxr-x--- 3 team-lead orion-team 4096 Aug 30 12:00 /srv/projects/orion
# file: srv/projects/orion
# owner: team-lead
# group: orion-team
user::rwx
group::r-x
other::---
```

There is no `+` on the mode string and no `mask::` line in the `getfacl` output. This tree has only the standard owner, group and other permissions right now.

### What the output means

On a file with no extended ACL, `getfacl` simply repeats the standard bits in ACL notation. The `user::`, `group::` and `other::` lines match the three traditional buckets. That is not an error. It is `getfacl` saying "so far, this file's access is just those three buckets."

The fast way to see *whether* a file has an extended ACL is the trailing `+` in `ls -l`. A plain directory shows `drwxr-x---`. One with an ACL shows `drwxr-x---+`. No `+` means no extended ACL.

## Granting access without touching group membership

A **named-user** ACL entry gives one specific user a set of permissions, whatever groups they are in. Think of it as one line on the guest list. Its form reads from left to right: `u:name:perms` (long form `user:name:perms`), that is the kind of entry, the name, and the permissions.

### Add two named users and watch the `+` appear

`setfacl` (short for *set file ACL*) with `-m` (**m**odify) adds or updates an entry. Give `contractor-jane` read, write and enter, and `auditor-tom` read and enter, on the whole tree:

```sh
sudo setfacl -R -m u:contractor-jane:rwx /srv/projects/orion
sudo setfacl -R -m u:auditor-tom:rx /srv/projects/orion
ls -ld /srv/projects/orion
getfacl /srv/projects/orion
```

Expect something like:

```text
drwxrwx---+ 3 team-lead orion-team 4096 Aug 30 12:00 /srv/projects/orion
# file: srv/projects/orion
# owner: team-lead
# group: orion-team
user::rwx
user:contractor-jane:rwx
user:auditor-tom:r-x
group::r-x
mask::rwx
other::---
```

The `+` is now on the mode string. Two `user:` lines name the two users, and `# owner:` and `# group:` are unchanged. A `mask::` line appeared on its own. It caps every named entry, and you will meet it again when an entry seems not to work.

### Two details that carry the weight

The command worked because of two choices:

- **`-R` (recursive).** Without it, `setfacl -m` changes only the directory itself. Every file and subdirectory already inside keeps its old permissions. `-R` walks the whole tree and adds the entry to everything in it.
- **`rwx`, not `rw-`, on a directory.** On a directory, the execute bit means "you may pass through this": `cd` into it, or reach a file inside by its path. Grant only `rw-` and the user cannot go into any subdirectory. "Read and write access to a tree" always needs the execute bit on every directory.

## Common pitfalls

> [!WARNING]
> - **`setfacl -m` without `-R` on a tree that already has files.** The existing files are not changed. Use `-R` for content that already exists.
> - **`rw-` on a directory entry.** The user cannot pass into the directory. Directories need `x` (`rwx` or `r-x`).
> - **Reaching for a new group instead.** Every one-off exception becomes a permanent group to track and clean up. That is the cost ACLs exist to avoid.
