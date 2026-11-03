# Primary Groups And Moving A Home

Astronaut, every crew member on your ship has one home team and can carry extra team badges. This part shows you how to read both, how to move a crew member to a new home team, and how to move their quarters (their home directory) without leaving their belongings behind.

## Primary groups and supplementary groups

Every Linux user has exactly one **primary group** and any number of **supplementary groups**. The difference decides who owns the files a user creates, so it is worth getting straight before you change anything.

### Read both groups with `id`

The `id` command (short for *identity*) prints a user's number, their primary group and their full group list in one line.

<!-- astrona:playground:renew -->

Run it for `user1`:

```sh
id user1
```

Expect something like:

```text
uid=1001(user1) gid=1001(user1) groups=1001(user1),1002(web)
```

`gid=` is the primary group, here the user's own private group `user1`. Everything after `groups=` is the full membership: the primary group, plus the supplementary group `web`. The numbers on your machine may differ. The shape is what matters.

### What each kind of group does

Now the rule behind that output:

- The **primary group** is one GID (group ID number) stored in the account's line in `/etc/passwd`. Think of it as the crew member's home team: every new crate (file) they pack gets this team's tag. A new login session also starts with it as the active group.
- **Supplementary groups** are every other group the user belongs to, listed in `/etc/group`. They are extra team badges. They open shared places, such as a `dev` group's source tree or an `op` group's log directory, but they do not change who owns the user's new files.

## Changing the primary group

The `usermod` command (short for *user modify*) changes an existing account. A lowercase `-g` sets the primary group.

### Move `user1` to the `dev` team

Change the primary group, then check it:

```sh
sudo usermod -g dev user1
id user1
```

Expect something like:

```text
uid=1001(user1) gid=1003(dev) groups=1003(dev),1002(web)
```

`gid=` now shows `dev`. The supplementary list still has `web`: changing the primary group left it alone.

### What `-g` does not touch

`usermod -g` rewrites exactly one field in `/etc/passwd` and nothing else. It does not change any file on disk. Files that `user1` already owns keep their old group until someone changes them with `chgrp`. The `usermod` manual page describes `-g` only in terms of that one account record, and that is its whole effect.

## Moving a home directory

Moving a home directory trips people up because it is really two jobs. One job changes the **pointer**: the path written in the account record. The other job moves the **contents**: the files in the old quarters.

### The pointer only: `-d`

The `-d` option (for home **d**irectory) on its own changes the pointer:

```sh
sudo usermod -d /home/accounts/user1 user1
```

This rewrites only the home path in `/etc/passwd`. It does not create the new directory and does not move a single file. The account now believes its quarters are at a path that may not exist. Do not run this one in your playground; it is here to show the difference.

### The pointer and the contents: `-d` with `-m`

The `-m` option (long form `--move-home`) does the move. Used together with `-d`, it changes the pointer **and** moves the contents to the new path. If you leave out `-m`, the account points at an empty place while the user's real files sit forgotten at the old path.

Two problems can stop the move:

- **A missing parent directory.** `usermod -m -d` creates the last directory in the path, but not missing directories above it. If `/home/accounts` does not exist, the command fails.
- **A logged-in user.** If the account has a live login session or a running process, `usermod` may refuse the move. Log the user out first.

### Watch the missing parent fail, then fix it

Your playground has no `/home/accounts` yet, so the first try fails. Create the parent, try again, and look at the result:

```sh
sudo usermod -d /home/accounts/user1 -m user1
sudo mkdir -p /home/accounts
sudo usermod -d /home/accounts/user1 -m user1
getent passwd user1
ls -a /home/accounts/user1
```

Expect something like:

```text
usermod: cannot create directory /home/accounts/user1
...
user1:x:1001:1003:...:/home/accounts/user1:/bin/bash
.  ..  .bash_logout  .bashrc  .profile  ORIGINAL-HOME-MARKER.txt
```

The first call fails because `/home/accounts` is missing. After `mkdir -p`, the second call rewrites the home field in the account record. The marker file that started in `/home/user1` is now in `/home/accounts/user1`. That proves the contents moved, not just the pointer.

### Check with `getent`

`getent` (short for *get entries*) asks the ship's records officer for an account. It prints the record exactly as the system itself would use it, from every source the system trusts, not only the local `/etc/passwd` file. That makes it a better check than `grep` on a file.

## Common pitfalls

> [!WARNING]
> - **`usermod -d` without `-m`.** You changed only the pointer, and the files stay at the old path. Always use both when you mean "move".
> - **The parent directory is missing.** Create it first with `mkdir -p` (here `/home/accounts`). `usermod` does not create it for you.
> - **The user is still logged in.** `usermod -m` can refuse. Make sure the user has no open session and no running process.
> - **Expecting `-g` to change old files.** A new primary group only affects files created from now on. Existing files keep their group.
