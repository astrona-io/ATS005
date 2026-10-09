# A Scoped sudo Rule

Astronaut, sometimes a crew member needs the captain's authority for one order only. This part shows you how to write a `sudo` rule that grants exactly one command with no password, how to save it without risking the whole ship, and how to prove the grant is as narrow as you meant.

## One command, not the whole ship

`sudo` reads its rules from the captain's standing orders: the file `/etc/sudoers` and the extra pages clipped to it in `/etc/sudoers.d/`. How you word a rule there decides whether you hand out one order or the whole captain's authority.

### The shortcut that grants too much

Say `user2` needs to run exactly one script owned by `root`, `/root/dangerous.sh`, with no password. The tempting shortcut is this rule:

```text
user2 ALL=(ALL) NOPASSWD: ALL
```

It works. It also lets `user2` run *any* command as `root`, forever, with no password.

### The rule that names the command

The correct rule names the exact command:

```text
user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh
```

Read it from left to right: the user `user2`, on `ALL` hosts, running as `(root)`, with `NOPASSWD` (no door code needed), but **only** for that exact command. The `sudoers` manual page (`man 5 sudoers`) describes this `user host=(runas) tag: command` pattern under "User Specification".

## The command must match exactly

`sudo` compares what the user types with the rule **word for word**, arguments included. Small differences that look harmless to a person are a different command to `sudo`.

### A script is not the same as `bash` plus a script

A rule for `/root/dangerous.sh` alone matches `sudo /root/dangerous.sh`, which relies on the script's first line to start the shell. It does **not** match `sudo bash /root/dangerous.sh`. That is a different command: the `bash` program, plus one argument.

### Use the real path of `bash`

The rule needs the full path of `bash`. Find it on this machine first:

<!-- astrona:playground:renew -->

```sh
which bash
```

On Ubuntu 24.04 this is usually `/usr/bin/bash`, and `/bin/bash` may point to it. `sudo` matches the full path, so write the one that `which bash` reports.

## Saving the rule safely

One broken line in the standing orders can stop `sudo` working for everyone on the ship. So you never edit them with a plain editor. You go through a clerk who checks them first.

### Write a drop-in file with `visudo`

`visudo` (short for *vi sudo*, though it uses the editor in your `$EDITOR` variable) checks the syntax before it saves. For one scoped rule, use a drop-in file under `/etc/sudoers.d/` instead of the main file. A drop-in is easier to review, add and remove, and package upgrades leave it alone.

Open the drop-in with `visudo`:

```sh
sudo visudo -f /etc/sudoers.d/user2-dangerous-script
```

`visudo -f <path>` checks a drop-in file the same way it checks the main file. It refuses to save a broken rule. That is what stands between one typo and a ship where nobody can use `sudo`.

In the editor, write this one line, with the path that `which bash` reported, then save and quit:

```text
user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh
```

### Lock the file and check every rule

Set the permissions and the owner, then check all the rules at once:

```sh
sudo chmod 0440 /etc/sudoers.d/user2-dangerous-script
sudo chown root:root /etc/sudoers.d/user2-dangerous-script
sudo visudo -c
```

`sudo` refuses to use a rules file that its group or other users can write to. `visudo -c` (for **c**heck) reads the main file and every drop-in in one pass.

## Proving the grant is narrow

Two `sudo` options show rules without running anything. `sudo -l` (for **l**ist) prints the rules that apply to you. `sudo -l -U <user>` prints the rules for *another* user without becoming them. That is the direct way to see that a grant is exactly as narrow as you meant.

### List the rule and run the command as `user2`

Check the files again, list `user2`'s rules, and run the command as `user2`:

```sh
sudo visudo -c
sudo -l -U user2
sudo -u user2 sudo -n bash /root/dangerous.sh
```

Expect something like:

```text
/etc/sudoers: parsed OK
/etc/sudoers.d/user2-dangerous-script: parsed OK
...
User user2 may run the following commands on this host:
    (root) NOPASSWD: /usr/bin/bash /root/dangerous.sh
dangerous.sh ran as root at 2026-08-30T12:00:00+00:00
```

`sudo -l -U user2` lists exactly one command. The last line ran it with no password prompt. The `-n` option (non-interactive) makes `sudo` fail at once instead of asking for a password if the rule did *not* match, so it is a reliable check. Try `sudo -u user2 sudo -n whoami` and it is refused: the grant really is that narrow.

### Check every change in this module

These read-only commands confirm every change you made to `user1` and `user2` in your playground:

```sh
id user1                      # gid= should show dev
getent passwd user1           # home field should show /home/accounts/user1
ls -a /home/accounts/user1    # user1's original files, marker file included
id user2                      # groups= should include dev and op
sudo -l -U user2              # should list the one NOPASSWD command
```

## Common pitfalls

> [!WARNING]
> - **The rule names `/root/dangerous.sh`, but the user runs `sudo bash /root/dangerous.sh`.** No match. Write the exact command line, `bash` and its argument included.
> - **The wrong path for `bash`.** Use what `which bash` reports on this machine (`/usr/bin/bash` or `/bin/bash`). `sudo` matches the full path.
> - **Editing `/etc/sudoers` with a plain editor.** One bad line can lock everyone out of `sudo`. Always use `visudo` (or `visudo -f` for a drop-in), and run `visudo -c` afterwards.
> - **A drop-in file that others can write to.** `sudo` ignores it. Use `chmod 0440` and the owner `root:root`.

## Your mission: User & Group Provisioning and Scoped Sudo Lab

You can now move an account to a new team and new quarters, create an account with the right badges in one command, and grant one exact order through `sudo`. Now prove it in a graded mission: a fresh ship where `user1` still has its old group and home, `user2` does not exist yet, and `user2` needs one exact `sudo` command.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop user-group-mgmt-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-011
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-011
```

Read the task in [`question.md`](../../../labs/lab-011/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-011
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-011
astrona start user-group-mgmt-playground
```
