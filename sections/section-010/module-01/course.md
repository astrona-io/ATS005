# User & Group Account Management

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS005/tree/main/sections/section-010/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-010/module-01/playground
> astrona destroy user-group-mgmt-playground
> ```

Every Linux administrator eventually inherits an account that was set up wrong: a new hire in the wrong team's group, a home directory that was never moved when the company reorganised its filesystem. Fixing these looks like trivial `useradd` / `usermod` busywork. It is not. Under a handful of short commands sit three separate, easy-to-confuse mechanisms — how a *primary* group differs from a *supplementary* one, how moving a home directory's *pointer* differs from moving its *contents*, and how a `sudo` grant can be a scalpel or a sledgehammer depending on how you word the rule.

> *In `sudoers`, "close enough" is a fail — the command string must match exactly, or `NOPASSWD` never triggers.*

## Learning objectives

After this module you can:

- Distinguish a primary group from a supplementary group and read both out of `id` output.
- Change an existing account's primary group with `usermod -g`, and state what that does and does not touch on disk.
- Relocate a home directory with `usermod -m -d`, accounting for the missing-parent and active-session constraints.
- Provision a new account with the right supplementary groups, shell, and home path in a single `useradd` call.
- Explain why `usermod -G` and `usermod -aG` behave differently on an existing user, and pick the safe one.
- Write and validate a single-command `NOPASSWD` rule as an `/etc/sudoers.d/` drop-in.

## Before you start

You should be comfortable moving around a shell, running commands with `sudo`, and editing a file. You do not need prior `useradd` experience — that is what this module builds. It helps to know that `/etc/passwd` holds one line per account and `/etc/group` holds one line per group; the commands here edit those files for you.

The playground VM already has:

- Groups `dev`, `op`, and `web`.
- User `user1` with a default home at `/home/user1`, its own private primary group, and supplementary membership in `web`. A file `~user1/ORIGINAL-HOME-MARKER.txt` marks the original home.
- `/root/dangerous.sh`, a root-owned script, for the scoped-`sudo` section.
- **No** `/home/accounts` directory yet — deliberately.

Open a shell on it with:

```sh
astrona ssh astro-user-group-mgmt-playground
```

Every command block below runs **inside that VM**, as a normal user with `sudo` available.

## Where this fits

Local accounts and groups are the base layer of Linux identity. Later modules add password aging and locking (Module 3), POSIX ACLs and PAM limits (Section 020), and directory-backed identity with LDAP (Section 040) — but every one of those assumes you can already provision an account into the right groups and hand out privilege precisely. The two mistakes this module guards against — replacing a group list instead of extending it, and granting `ALL` where one command was meant — are exactly the ones that stay invisible until an audit or an incident surfaces them.

## Primary groups vs. supplementary groups

Every Linux user has exactly one **primary group** and any number of **supplementary groups**.

- The **primary group** is a single GID (group ID) field in the account's `/etc/passwd` line. It is the group that new files the user creates are owned by, and the group a fresh login session starts with as "the" active group.
- **Supplementary groups** are every *other* group the user belongs to, listed in `/etc/group`. They grant access to shared things — a `dev` group's source tree, an `op` group's log directory — without changing what group owns the user's own new files.

`id` prints both at once. Read the name as short for *identity*: it reports the caller's (or a named user's) UID, primary GID, and full group list.

> [!TIP]
> **Try it — read an account's primary vs. supplementary groups**
>
> ```sh
> id user1
> ```
>
> Expect something like:
>
> ```text
> uid=1001(user1) gid=1001(user1) groups=1001(user1),1002(web)
> ```
>
> `gid=` is the primary group (here `user1`'s own private group). Everything after `groups=` is the full membership — primary group included, plus the supplementary `web`. UIDs and GIDs on your VM may differ; the structure is what matters.

To change the *primary* group, `usermod` (read: *user modify*) takes a lowercase `-g`:

```sh
sudo usermod -g dev user1
```

This rewrites exactly one field in `/etc/passwd` and nothing else. It touches no files on disk and does not retroactively `chgrp` anything `user1` already owns — files group-owned by the old primary group keep that ownership until someone explicitly changes them. `man usermod` scopes the `-g` description purely to the passwd record; that is the whole effect.

> [!TIP]
> **Try it — confirm the primary group moved, and only that**
>
> ```sh
> sudo usermod -g dev user1
> id user1
> ```
>
> Expect something like:
>
> ```text
> uid=1001(user1) gid=1003(dev) groups=1003(dev),1002(web)
> ```
>
> `gid=` now shows `dev`. The supplementary list still has `web` — changing the primary group left it alone.

## Moving a home directory — the pointer vs. the contents

Relocating a home directory trips people up because it is really *two* operations sharing one flag's clothing.

Running `-d` (the home **d**irectory field) alone changes the pointer only:

```sh
sudo usermod -d /home/accounts/user1 user1
```

That rewrites only the home-directory *path* recorded in `/etc/passwd`. It does not create the new directory and does not move a single byte. The account now believes its home is a path that may not exist.

The flag that performs the move is `-m` (`--move-home`) — it changes the pointer *and* moves the contents:

```sh
sudo usermod -d /home/accounts/user1 -m user1
```

`-m` copies the *contents* of the old home into the new path, and only works together with `-d`. Skip it and you have silently pointed the account at an empty directory while the user's real files sit abandoned at the old path.

Two constraints bite here. First, `usermod -m -d` creates the target **leaf** directory but not missing **parent** directories — if `/home/accounts` does not exist, the command fails outright. Second, if the account has a live login session or a running process, `usermod` may refuse the move; log the account out first.

> [!TIP]
> **Try it — watch the missing parent fail, then fix it**
>
> ```sh
> sudo usermod -d /home/accounts/user1 -m user1
> sudo mkdir -p /home/accounts
> sudo usermod -d /home/accounts/user1 -m user1
> getent passwd user1
> ls -a /home/accounts/user1
> ```
>
> Expect something like:
>
> ```text
> usermod: cannot create directory /home/accounts/user1
> ...
> user1:x:1001:1003:...:/home/accounts/user1:/bin/bash
> .  ..  .bash_logout  .bashrc  .profile  ORIGINAL-HOME-MARKER.txt
> ```
>
> The first call fails because `/home/accounts` is missing. After `mkdir -p`, the second call rewrites the passwd home field **and** the marker file that started life in `/home/user1` is now under `/home/accounts/user1` — proof the contents moved, not just the pointer.

`getent` (read: *get entries*) is the right verification tool here — more on why it beats `grep /etc/passwd` in Module 2. For now: it prints the resolved account record the system itself would use.

> [!WARNING]
> **Common pitfalls — moving a home directory**
>
> - `usermod -d` **without** `-m` — you changed only the pointer; the files are stranded at the old path. Always pair them when you mean "move".
> - Target parent missing — `mkdir -p` the parent (`/home/accounts`) first; `usermod` will not create it for you.
> - Account still logged in — `usermod -m` can refuse. Make sure the user has no active session or running process.

## Provisioning a brand-new account correctly

A new account has no prior state to damage, so `useradd` (read: *user add*) builds the whole identity in one call:

```sh
sudo useradd -m -d /home/accounts/user2 -G dev,op -s /bin/bash user2
```

- `-m` creates the home directory and seeds it from `/etc/skel` (there is nothing to move — the account is new).
- `-d /home/accounts/user2` sets the home path at creation time, so no separate move step is needed.
- `-G dev,op` sets the **supplementary** group list — comma-separated, no spaces.
- `-s /bin/bash` sets the login shell.

Note that `useradd` has no `-a` "append" flag and needs none: there is no existing group list to protect. Every group in `-G` simply becomes part of the new account from the start.

> [!TIP]
> **Try it — provision user2 in one call**
>
> ```sh
> sudo useradd -m -d /home/accounts/user2 -G dev,op -s /bin/bash user2
> id user2
> getent passwd user2
> ```
>
> Expect something like:
>
> ```text
> uid=1002(user2) gid=1002(user2) groups=1002(user2),1003(dev),1004(op)
> user2:x:1002:1002:...:/home/accounts/user2:/bin/bash
> ```
>
> `groups=` carries both `dev` and `op`; the passwd record shows the home path and shell you asked for — all from the single command.

### The `-G` vs. `-aG` trap on existing users

The behaviour that has no downside on `useradd` becomes the single most consequential character in this module on `usermod`. On an account that **already exists**:

```sh
sudo usermod -G datateam user1     # REPLACES the entire supplementary list
sudo usermod -aG datateam user1    # APPENDS datateam, keeps the rest
```

If `user1` belonged to five groups and you run plain `-G datateam`, all five are gone, replaced by a list containing only `datateam`. The `-a` (append) flag is what makes it additive. The tool gives no warning either way.

> [!TIP]
> **Try it — see append preserve the existing list**
>
> ```sh
> id user1
> sudo usermod -aG op user1
> id user1
> ```
>
> Expect something like:
>
> ```text
> uid=1001(user1) gid=1003(dev) groups=1003(dev),1002(web)
> uid=1001(user1) gid=1003(dev) groups=1003(dev),1002(web),1004(op)
> ```
>
> `op` is added; `web` and the `dev` primary group are untouched. Re-run with `-G op` instead of `-aG op` on a throwaway user and you will see `web` disappear — that is the trap.

## Scoped sudo — a scalpel, not a sledgehammer

Say `user2` needs to run exactly one root-owned script, `/root/dangerous.sh`, with no password. The tempting shortcut:

```text
user2 ALL=(ALL) NOPASSWD: ALL
```

works — and also lets `user2` run *any* command as root forever with no password. The correct rule names the exact command:

```text
user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh
```

Read left to right: user `user2`, on `ALL` hosts, running as `(root)`, `NOPASSWD`, but **only** for that exact command string. `man 5 sudoers` documents the full `user host=(runas) tag: command` grammar under "User Specification".

### Exact-string matching is not optional

`sudo` matches what the user actually types against the rule **literally**, arguments included. A rule for `/root/dangerous.sh` alone matches `sudo /root/dangerous.sh` (relying on the script's shebang) — it does **not** match `sudo bash /root/dangerous.sh`, which is a different command line: the `bash` binary plus an argument. Resolve the real path of `bash` first with `which bash` (commonly `/usr/bin/bash`, sometimes with `/bin/bash` as a symlink); sudoers matches the resolved absolute path.

### Editing sudoers safely

Never open `/etc/sudoers` in a plain editor. Use `visudo` (read: *vi sudo*, though it honours `$EDITOR`), which syntax-checks before saving. For one scoped rule, use a drop-in file under `/etc/sudoers.d/` rather than the monolithic file — easier to audit, add, and remove, and it survives package upgrades:

```sh
sudo visudo -f /etc/sudoers.d/user2-dangerous-script
```

`visudo -f <path>` applies the same validation to a drop-in as to the main file; it refuses to save a broken rule, which is what stands between one typo and locking `sudo` for everyone on the box.

After writing the rule, fix permissions and validate everything:

```sh
sudo chmod 0440 /etc/sudoers.d/user2-dangerous-script
sudo chown root:root /etc/sudoers.d/user2-dangerous-script
sudo visudo -c
```

`sudo` refuses to honour a sudoers file that is group- or world-writable, and `-c` (check) validates the main file plus every drop-in in one pass.

> [!TIP]
> **Try it — write the scoped rule and confirm it**
>
> Put this one line in `/etc/sudoers.d/user2-dangerous-script` (via `sudo visudo -f`), matching the path `which bash` reports:
>
> ```text
> user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh
> ```
>
> Then:
>
> ```sh
> sudo chmod 0440 /etc/sudoers.d/user2-dangerous-script
> sudo visudo -c
> sudo -l -U user2
> sudo -u user2 sudo -n bash /root/dangerous.sh
> ```
>
> Expect something like:
>
> ```text
> /etc/sudoers: parsed OK
> /etc/sudoers.d/user2-dangerous-script: parsed OK
> ...
> User user2 may run the following commands on this host:
>     (root) NOPASSWD: /usr/bin/bash /root/dangerous.sh
> dangerous.sh ran as root at 2026-08-30T12:00:00+00:00
> ```
>
> `sudo -l -U user2` lists exactly the one command. The final line runs it with no password prompt; `-n` (non-interactive) makes `sudo` fail loudly instead of prompting if the rule did *not* match, so it is a reliable check. Try `sudo -u user2 sudo -n whoami` and it is denied — the grant really is that narrow.

> [!WARNING]
> **Common pitfalls — scoped sudo**
>
> - Rule names `/root/dangerous.sh` but the user runs `sudo bash /root/dangerous.sh` — no match. Match the *exact* invoked command line, `bash` and its argument included.
> - Wrong `bash` path — use whatever `which bash` reports on this host (`/usr/bin/bash` vs `/bin/bash`); sudoers matches the resolved absolute path.
> - Editing `/etc/sudoers` directly with a plain editor — one bad line locks `sudo`. Always go through `visudo` (or `visudo -f` for a drop-in), and run `visudo -c` afterwards.
> - Drop-in file group- or world-writable — `sudo` silently ignores it. `chmod 0440`, owner `root:root`.

## Checking your work

These read-only commands, run in the VM, confirm each change landed:

```sh
id user1                      # gid= should show dev
getent passwd user1           # home field should show /home/accounts/user1
ls -a /home/accounts/user1    # user1's original files, marker file included
id user2                      # groups= should include dev and op
sudo -l -U user2              # should list the one NOPASSWD command
```
