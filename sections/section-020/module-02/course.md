# PAM Resource Limits: Making a Restriction Actually Stick

Astronaut, one crew member who starts helpers faster than the ship can count them can bring a whole shared ship down. A process that forks itself again and again is one of the oldest ways to crash a server. The quick fix, "cap it with `ulimit`", is right in spirit. It goes wrong the moment someone bolts it onto one user's `~/.bashrc`.

This module builds the restriction the way it really holds. You write an entry in `/etc/security/limits.d/`, and a PAM module applies it at login, however the session started. PAM (Pluggable Authentication Modules) is the airlock checklist every crew member passes through when they come aboard.

## Learning objectives

After this module you can:

- Explain why a `ulimit` line in `~/.bashrc` leaves cron jobs and non-interactive `ssh host cmd` runs without a limit.
- Tell a soft limit from a hard limit, and say which one a normal user cannot raise.
- Read a user's live limit with `ulimit` in their own session, or with `prlimit --pid` from anywhere.
- Write a hard `nproc` limit as a drop-in file in `/etc/security/limits.d/`, in the four-column format.
- Check that `pam_limits.so` is in the PAM `session` stack for the login path, and explain why the file does nothing without it.
- Cap concurrent logins for a whole group with `@group hard maxlogins`.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **What a shell startup file is.** `~/.bashrc` and similar files run commands when a shell starts.
- **How to run a command as another user.** `sudo -u <user> <command>`.
- **How to edit a file as `root`.** For example with `sudo nano <file>`.

"PAM" here just means the stack of modules the system runs when a session opens. You will read one line of it, not rewrite it.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- `jackie`, with `ulimit -Su 150` added to `~/.bashrc` (the fragile "fix"), and a long-running process (the `systemd-run` unit `jackie-sleeper`) so `prlimit` has something to read.
- The group `operators`, with the members `ops-anna`, `ops-ben` and `ops-carl`.
- `pam_limits.so` already switched on in `/etc/pam.d/common-session`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh pam-limits-playground
```

Every command block in the parts runs **inside that virtual machine**.

## How this module is laid out

1. [Why A .bashrc Limit Is Not Enough](./course-01-why-a-bashrc-limit-is-not-enough.md): the hole in a `~/.bashrc` fix, soft and hard limits, and reading the live value.
2. [Hard Limits Through PAM](./course-02-hard-limits-through-pam.md): the four-column `limits.d` format, `pam_limits.so`, and removing the old line.
3. [One Login Per Group Member](./course-03-one-login-per-group-member.md): `@group hard maxlogins`.
   - Mission: [PAM Hard Limits & maxlogins Lab](../../../labs/lab-022/docs/question.md)
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md)

## Why this matters

A limit that only works when a user logs in "the normal way" is not really enforced. The scripted and automated jobs most likely to fork out of control are exactly the ones that skip `~/.bashrc`.

Limits from `pam_limits.so` apply when a session *opens*. So an already-open shell never shows a change; you always check from a fresh login.

> *If a resource limit only works when a user logs in "the normal way", it is not really enforced. `pam_limits.so` is what makes a limit apply everywhere.*
