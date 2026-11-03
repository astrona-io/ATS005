# ACLs On Whole Trees: Recursion, Backup And Restore

Astronaut, a guest list taped to one crate is easy. A real cargo hold has hundreds of crates in nested compartments, and a careless cleanup can tear every guest list off in one command. This module shows you how to work on a whole tree at once, and how to photograph every guest list so you can put them back.

## Learning objectives

After this module you can:

- Read and change the ACL of a whole tree with `getfacl -R` and `setfacl -R`.
- Use the capital `X` so directories and programs get the pass-through right, and plain files do not.
- Remove one user's entries from a tree with `setfacl -R -x`, and every entry with `setfacl -R -b`.
- Save the ACLs of a tree with `getfacl -R -p`, and put them back with `setfacl --restore`.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **Named ACL entries.** `setfacl -m u:<user>:<perms>` adds a named user to a guest list, and `getfacl` reads it.
- **Default ACLs.** `setfacl -d -m` sets the guest list that new files are born with.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- A tree `/srv/data/ledger` with two year folders, a few files and one script, owned by `ledger-owner`.
- ACL entries on the whole tree for `auditor-ivy` and `temp-vendor`, and one extra entry for `ledger-clerk` on one file.
- A script `/root/strip-acls.sh` that removes every ACL entry from the tree, like a careless cleanup would.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh acl-backup-playground
```

Every command block in the parts runs **inside that virtual machine**.

## How this module is laid out

1. [ACLs On A Whole Tree](./course-01-acls-on-a-whole-tree.md): `getfacl -R`, `setfacl -R`, the capital `X`, and removing entries.
2. [Backup And Restore](./course-02-backup-and-restore.md): `getfacl -R -p` into a file, and `setfacl --restore`.
   - Mission: [ACL Tree Backup And Restore Lab](../../../labs/lab-024/docs/question.md)
3. [Wrap-Up: Mission Debrief](./course-03-wrap-up.md)

## Why this matters

ACLs live in the file system, not in a file you can copy. A restore from a normal file backup, a `cp` or a moved directory can drop them without a sound. The exam asks for the recursive forms, and a real ship needs the backup habit.

> *Photograph the guest lists before you tidy the hold.*
