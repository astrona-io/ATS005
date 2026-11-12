# The Forest of Environment Files

Astronaut, every crew member who comes aboard gets a briefing pack: a set of environment variables that every program they start can read. On Ubuntu, a small forest of files can each add a line to that pack: `/etc/environment`, `/etc/profile`, everything under `/etc/profile.d/`, and a personal layer per user (`~/.profile`, `~/.bash_profile`, `~/.bash_login`, `~/.bashrc`). It looks like clutter. It is not.

Each file answers two questions: *who* does this variable apply to, and *what kind of session* may see it? Put a variable in the wrong file and the failure is exact and repeatable. It works over your SSH connection, and it is quietly missing from a cron job, a systemd unit, or a colleague's new terminal tab. This module builds the map that prevents that.

## Learning objectives

After this module you can:

- Explain why `/etc/environment` takes only `KEY=VALUE` lines (no `export`, no expansion), and which component reads it.
- Choose between `/etc/environment` and `/etc/profile.d/*.sh`, based on whether you need shell logic and which session types must see the variable.
- Trace which startup files a login shell reads, and which an interactive non-login shell reads.
- Put a personal variable in the right dotfile, so it affects one account and the right session type.
- Explain why cron jobs and systemd services do not get profile variables, and how to give them one.
- Check an environment change from a fresh session of the right type, not from the shell you edited in.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **What an environment variable is**, and what `export` does in a shell.
- **How to edit a file as `root`**, for example with `nano`.
- **Two ways to switch user.** `su - <user>` starts a *login* shell as that user, and plain `su <user>` starts a *non-login* one. That difference is half of this module.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- The users `candidate` and `otheruser`: ordinary accounts. Reach them with `su - candidate` from `root`, with no password.
- `/etc/cron.d/env-probe`: a cron job that writes its environment to `/home/candidate/cron-env.txt` every minute.
- `env-probe.service`: a systemd unit that writes its environment to `/run/env-probe.txt` when it starts.
- `/etc/environment`, `/etc/profile.d/` and every dotfile, untouched.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh env-profiles-playground
```

Every command block in the parts runs **inside that virtual machine**, as `root` unless it says otherwise. Become `root` first with `sudo -i`. The `env` command, with no arguments, prints the full environment of the process that runs it; you will use it to check results.

## How this module is laid out

1. [The Ship-Wide Notice Board](./course-01-the-ship-wide-notice-board.md): `/etc/environment`, read by `pam_env.so` for every session.
2. [Login Scripts In /etc/profile.d](./course-02-login-scripts-in-profile-d.md): real shell scripts that only login shells read.
3. [Login Shells, Non-Login Shells And Personal Variables](./course-03-login-and-non-login-shells.md): which startup files each shell reads, and where a personal variable belongs.
   - Mission: [System-Wide and Personal Environment Variables Lab](../../../labs/lab-031/docs/question.md)
4. [The Sessions That See None Of This](./course-04-cron-and-systemd.md): what cron jobs and systemd services really get.
5. [Wrap-Up: Mission Debrief](./course-05-wrap-up.md)

## Why this matters

`/etc/environment` is read by `pam_env.so`, a module of PAM (Pluggable Authentication Modules, the airlock checklist every crew member passes through when coming aboard). Like every PAM step, it reads its file once, when a session is set up.

Cron and systemd sit outside the shell profile world entirely. That is why a variable that "works everywhere" in testing can still be missing from a scheduled job, and why the exam checks that you pick the right file for the session that needs it.

> *Pick the file by asking two questions: who must see the variable, and through which door do they come aboard?*

<!-- curriculum-practice -->
## Practice and assessment

- [System-Wide and Personal Environment Variables Lab](../../../labs/lab-031/docs/question.md): Set a variable for every user's login and non-login shells through /etc/environment; Set a personal variable for one user only in their login profile.
- [Shell Environment & PATH Capstone Lab](../../../labs/lab-030/docs/question.md): Export a variable for every login shell through a profile.d script; Set a personal variable and extend PATH for one user only; Prove that a decoy script never replaces a real system command.
