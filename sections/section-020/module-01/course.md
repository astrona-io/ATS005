# Access Control Lists: Permissions Beyond Three Buckets

Astronaut, the standard Linux permissions on a file have three buckets: the crate's owner, the owner's team, and everyone else aboard. Each bucket gets one set of `rwx` bits. For most crates (files) that is all you need. But the model has a ceiling built in.

The moment a project needs "this one outside contractor may read and write, this one auditor may only read, and neither of them joins the team", three buckets run out of room. POSIX access control lists (ACLs) fix this. An ACL is a guest list taped to one crate or compartment: it names extra users and groups and what each may do. It sits *on top of* the three buckets and never replaces them.

## Learning objectives

After this module you can:

- Explain why the owner, group and other model cannot express an exception for one user, and when an ACL beats creating a new group.
- Read a file's full ACL with `getfacl`, and spot an extended ACL from the `+` in `ls -l`.
- Grant one named user access with `setfacl -m`, using `-R` to cover content that already exists.
- Set default ACL entries with `setfacl -d` so files created later get the same access.
- Explain what the `mask` entry caps, and find an entry whose real permission is lower than it is written.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **Standard permissions.** The `rwx` bits, the owner, group and other split, `chmod` and `chown`.
- **Running a command as another user.** `sudo -u <user> <command>` runs one command as that user.

You do not need any ACL experience.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- `/srv/projects/orion`: a shared tree owned by `team-lead:orion-team`, mode `750`, already holding `README.md` and `docs/spec.md`.
- `contractor-jane` and `auditor-tom`: real accounts that are **not** in `orion-team` and must not be added to it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh posix-acl-playground
```

Every command block in the parts runs **inside that virtual machine**.

## How this module is laid out

1. [Reading And Granting ACL Entries](./course-01-reading-and-granting-acl-entries.md): `getfacl`, the `+` in `ls -l`, and named-user entries with `setfacl -R -m`.
2. [Default ACLs For Files Created Later](./course-02-default-acls.md): `setfacl -d -m`, and proof that ACLs only add access.
   - Mission: [ACL-Based Shared Directory Access Lab](../../../labs/lab-021/docs/question.md)
3. [The ACL Mask](./course-03-the-acl-mask.md): the entry that caps every other entry, and how to spot it.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md)

## Why this matters

There are three ways to share a directory: group membership, the setgid bit on a directory (so new files get the directory's group), and ACLs. The first two change *who is on the team*. ACLs leave the team alone and add exceptions beside it.

Reaching for a new group instead looks right, but every one-off exception then becomes a permanent group to track and clean up. ACLs exist to avoid that cost.

> *ACLs extend permissions, they do not replace them: the owner, group and other bits and the mask entry still cap what an ACL entry really grants.*
