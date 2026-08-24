# Chapter 1: User & Group Account Management

> *In `sudoers`, "close enough" is a fail — the command string must match exactly, or `NOPASSWD` never triggers.*

Every Linux system administrator eventually inherits an account that was set up wrong. Maybe a new hire was provisioned into the wrong team's group, or an old home directory was never relocated when a company reorganized its filesystem layout. Fixing these situations looks, on the surface, like trivial `useradd`/`usermod` busywork. It is not. Underneath a handful of short commands sit three distinct, easy-to-confuse mechanisms: how a *primary* group differs from a *supplementary* group, how moving a home directory's *pointer* differs from moving its *contents*, and how granting `sudo` access can either be a scalpel or a sledgehammer depending on exactly how you word the rule.

This chapter walks through all three, building toward the exact kind of task the LFCS exam loves: reassign an existing account's identity, provision a new one correctly the first time, and hand out the narrowest possible slice of root privilege.

---

## Part I: Primary Groups vs. Supplementary Groups

Every Linux user has exactly one **primary group** and, optionally, any number of **supplementary groups**. The distinction matters more than it first appears:

- The **primary group** is recorded as a single GID field in `/etc/passwd`. It is the group new files get created with by default, and it's the group a brand-new login session starts with as "the" group, before any supplementary memberships are even considered.
- **Supplementary groups** are the *other* groups a user belongs to, recorded in `/etc/group`. They grant access to shared resources — a `dev` group's shared source tree, an `op` group's shared log directory — without redefining what group owns a user's own new files.

You can inspect both at once:

```bash
id user1
```

```text
uid=1001(user1) gid=1001(user1) groups=1001(user1)
```

The `gid=` field is the primary group. Everything listed after `groups=` is the full membership list, primary group included.

To change a user's *primary* group, `usermod` takes a lowercase `-g`:

```bash
sudo usermod -g dev user1
```

This rewrites exactly one field in `/etc/passwd` — nothing else. It does not touch a single file on disk, and it does not retroactively `chgrp` anything `user1` already owns. If `user1` had files group-owned by their old primary group, those files keep that old group ownership until someone explicitly runs `chown`/`chgrp` on them. Check `man usermod`'s `-g` entry to confirm this yourself — the flag description is scoped purely to the passwd record.

---

## Part II: Moving a Home Directory — The Pointer vs. the Contents

Relocating a user's home directory is where a surprising number of administrators get tripped up, because the operation is actually *two* operations wearing one flag's clothing.

```bash
sudo usermod -d /home/accounts/user1 user1
```

Running `-d` alone changes only the **home directory field** in `/etc/passwd` — the pointer. It does not create the new directory, and it does not move a single byte of the old home directory's contents. The account now believes its home is a path that, as far as the filesystem is concerned, might not even exist yet.

The flag that actually performs the move is `-m`:

```bash
sudo usermod -g dev -d /home/accounts/user1 -m user1
```

`-m` (`--move-home`) tells `usermod` to copy the *contents* of the old home directory into the new path, and only takes effect when paired with `-d`. Check `man usermod`'s `-m, --move-home` entry — it explicitly states this dependency. Skip `-m`, and you've silently created an account pointed at an empty (or nonexistent) directory while the user's actual files sit abandoned at the old path.

One more gotcha: `usermod -m -d` will create the target **leaf** directory for you, but it will not create missing **parent** directories. If `/home/accounts` doesn't exist yet, the command fails outright. Confirm the parent exists first:

```bash
sudo mkdir -p /home/accounts
```

...before attempting the move. And if `user1` currently has an active login session or a running process, `usermod -m` may refuse to proceed at all — the fix there is to make sure the account is logged out first.

---

## Part III: Provisioning a Brand-New Account Correctly

Creating a new account has one structural advantage over modifying an existing one: there's no prior state to accidentally destroy. `useradd` builds the full identity in a single call:

```bash
sudo useradd -m -d /home/accounts/user2 -G dev,op -s /bin/bash user2
```

Breaking this down:

- `-m` creates the home directory and seeds it from `/etc/skel`, since this is a brand-new account with nothing to move.
- `-d /home/accounts/user2` sets the home directory path at creation time — no separate move step needed.
- `-G dev,op` sets the **supplementary** group list, comma-separated with no spaces. Check `man useradd`'s `-G, --groups` entry.
- `-s /bin/bash` sets the login shell.

Notice something important here: `useradd` has no `-a` "append" flag, and none is needed. There is no existing group list to accidentally wipe out — every group named in `-G` simply becomes part of the new account's membership from the start. That safety only becomes a concern once the account already exists, which brings us to the single most consequential character in this entire chapter.

### The `-G` vs. `-aG` Trap on Existing Users

On `usermod` — **not** `useradd` — `-G` behaves completely differently depending on whether the account is new or already exists:

```bash
sudo usermod -G datateam existinguser      # REPLACES the entire supplementary group list
sudo usermod -aG datateam existinguser     # APPENDS datateam, keeping everything else
```

If `existinguser` already belonged to five other groups and you run plain `-G datateam`, all five vanish, replaced by a list containing only `datateam`. The `-a` (append) flag is what turns this into a safe, additive operation. This distinction does not exist on `useradd`, because a new account has no prior list to protect — it only bites on `usermod`, and it bites hard, silently, with no warning from the tool itself.

---

## Part IV: Scoped Sudo — A Scalpel, Not a Sledgehammer

Granting `sudo` access is where good intentions most often turn into a security regression. Imagine `user2` needs to run exactly one root-owned maintenance script, `/root/dangerous.sh`, without a password. The tempting shortcut looks like this:

```
user2 ALL=(ALL) NOPASSWD: ALL
```

This works. It also means `user2` can now run *any command as root, forever, with no password* — a blanket grant that satisfies "the task passed" while creating a real vulnerability. The correct rule names the **exact** command:

```
user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh
```

Read left to right: user `user2`, on `ALL` hosts, running `(root)`, no password required, but **only** for that exact command string. Check `man 5 sudoers`'s "User Specification" grammar section for the full `user host=(runas) tag: command` breakdown.

### Exact-String Matching Is Not Optional

`sudo` evaluates the command a user actually invokes against the sudoers entry **literally**, arguments included. If the task specifies the user runs `sudo bash /root/dangerous.sh`, the sudoers rule must authorize the fully-resolved path to `bash` plus that exact argument — not just `/root/dangerous.sh` on its own (which would only match a direct `sudo /root/dangerous.sh` invocation relying on the script's shebang, not an explicit `bash` invocation). Confirm the real path first:

```bash
which bash
```

Typically `/usr/bin/bash`, often with `/bin/bash` as a symlink to it — but sudoers matching happens against the resolved absolute path, so use whichever `which` actually reports on the target system.

### Editing Sudoers Safely

Never open `/etc/sudoers` in a plain text editor. Use `visudo`, and for a single scoped rule, use a drop-in file instead of the monolithic file:

```bash
sudo visudo -f /etc/sudoers.d/user2-dangerous-script
```

`visudo -f <path>` applies the exact same syntax validation as editing the main file — it refuses to save a broken rule, which is what stands between you and locking `sudo` entirely for every user on the box over one typo. Drop-ins under `/etc/sudoers.d/` are also easier to audit, add, and remove individually, and they survive package upgrades cleanly.

After writing the rule, lock down permissions and validate everything:

```bash
sudo chmod 0440 /etc/sudoers.d/user2-dangerous-script
sudo chown root:root /etc/sudoers.d/user2-dangerous-script
sudo visudo -c
```

`sudo` itself refuses to honor a sudoers file that's group- or world-writable, and `-c` checks the main file plus every drop-in for syntax errors in one pass. Always run it after any sudoers change.

---

## Verifying Your Work

```bash
id user1                      # gid= should now show dev
getent passwd user1           # home directory field should show the new path
ls /home/accounts/user1       # user1's original files should be present
id user2                      # groups= should include both dev and op
sudo -l -U user2              # should list the exact NOPASSWD command
```

A working scoped rule should let this run with no password prompt at all:

```bash
su - user2 -c "sudo -n bash /root/dangerous.sh"
```

The `-n` flag forces `sudo` to run non-interactively — if a password *were* actually required, this fails loudly instead of hanging, which makes it a reliable pass/fail check rather than a guess.

## Self-Check

1. Why does `usermod -d` alone leave a user's files behind, and which single flag fixes that?
2. If `user2` is created fresh with `useradd -G dev,op`, is there any risk of wiping an existing group list? Why or why not?
3. Why does `NOPASSWD: /root/dangerous.sh` fail to match `sudo bash /root/dangerous.sh`, even though both reference the same script?
