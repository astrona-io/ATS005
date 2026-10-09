# User & Group Account Management

Astronaut, every Linux machine is a spaceship, and every person who works on it has an entry on the ship's crew roster. Sooner or later you inherit an entry that was set up wrong: a new crew member on the wrong team, or quarters (a home directory) that were never moved when the ship was reorganised. Fixing these looks like quick `useradd` and `usermod` work. It is not.

Under a few short commands sit three ideas that are easy to mix up. A *primary* group is not the same as a *supplementary* group. Moving the *pointer* to a home directory is not the same as moving its *contents*. And a `sudo` rule can hand out one exact order or the whole captain's authority, depending on how you word it. This module teaches all three, and the exam tests all three.

## Learning objectives

After this module you can:

- Tell a primary group from a supplementary group, and read both from the output of `id`.
- Change an existing account's primary group with `usermod -g`, and say what that does and does not change on disk.
- Move a home directory with `usermod -m -d`, including the missing-parent and logged-in-user problems.
- Create a new account with the right supplementary groups, shell and home path in one `useradd` command.
- Explain why `usermod -G` and `usermod -aG` behave differently on an existing user, and pick the safe one.
- Write and check a `NOPASSWD` rule for one exact command as a drop-in file in `/etc/sudoers.d/`.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **How to move around a shell.** You can change directory, list files and edit a file.
- **How to run a command with `sudo`.** `sudo` borrows the captain's authority (the `root` account) for one order.
- **Two account files exist.** `/etc/passwd` holds one line per account, and `/etc/group` holds one line per group. The commands in this module edit those files for you.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- The groups `dev`, `op` and `web`.
- The user `user1`, with its home at `/home/user1`, its own private primary group, and a supplementary membership in `web`. The file `ORIGINAL-HOME-MARKER.txt` in its home marks the original quarters, so you can see later whether a move took the contents along.
- The script `/root/dangerous.sh`, owned by `root`, for the `sudo` practice.
- **No** `/home/accounts` directory yet. That is on purpose.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh user-group-mgmt-playground
```

Every command block in the parts runs **inside that virtual machine**, as a normal user who can use `sudo`.

## How this module is laid out

1. [Primary Groups And Moving A Home](./course-01-primary-groups-and-moving-a-home.md): primary and supplementary groups, `usermod -g`, and moving a home directory with its contents.
2. [Creating A New Account In One Command](./course-02-creating-a-new-account.md): `useradd` with groups, home and shell, and the `-G` versus `-aG` trap.
3. [A Scoped sudo Rule](./course-03-a-scoped-sudo-rule.md): a `NOPASSWD` rule for one exact command, written safely with `visudo`.
   - Mission: [User & Group Provisioning and Scoped Sudo Lab](../../../labs/lab-011/docs/question.md)
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md)

## Why this matters

Local accounts and groups are the base layer of identity on Linux. Password aging, access control lists, resource limits and directory logins all assume you can already put an account in the right groups and hand out privilege precisely.

The two mistakes this module guards against stay invisible until an audit or an incident finds them. One is replacing a group list when you meant to extend it. The other is granting `ALL` when you meant one command.

> *In `sudoers`, "close enough" is a fail: the command must match exactly, or `NOPASSWD` never applies.*
