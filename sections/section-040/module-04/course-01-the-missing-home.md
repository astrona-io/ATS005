# The Missing Home

Astronaut, the registry says `newcomer` lives in `/home/newcomer`. This part shows you what happens when that folder does not exist, and where a new home would get its starter kit from.

## The directory stores a path, not a folder

The `homeDirectory` attribute of a directory user is only text. `sssd` hands that text to the system. Nothing in that chain creates the folder.

### See it in your playground

Ask for the user, then ask for the folder:

<!-- astrona:playground:renew -->

```sh
getent passwd newcomer
ls -d /home/newcomer
```

Expect the passwd line for `newcomer` with UID `10002` and home `/home/newcomer`. The `ls` command then fails with a "No such file or directory" message. The user is known, and the home is not there.

### What a login does without a home

Try a login shell as that user and print where you land:

```sh
sudo su - newcomer -c pwd
```

The shell starts, cannot enter the missing home, and falls back to `/`. A message about the missing directory is normal. `su -` starts a login, so it runs the same session steps as a real login.

## The starter kit in /etc/skel

When `useradd -m` creates a home, it copies everything from `/etc/skel` into it. `/etc/skel` is the ship's starter kit: shell start files and anything else you place there.

### Look inside

Show the starter kit, including hidden files:

```sh
ls -A /etc/skel
```

Expect the shell start files, such as `.bashrc`, `.profile` and `.bash_logout`. Files added here show up in every home created later. Homes that already exist are never changed.

## Common pitfalls

> [!WARNING]
> - **Thinking the directory creates the home.** It stores only the path.
> - **Putting a file in `/etc/skel` and expecting old homes to change.** Only new homes get a copy.
> - **Using `su` without the dash to test.** `su newcomer` skips the login steps. Use `su -`.
