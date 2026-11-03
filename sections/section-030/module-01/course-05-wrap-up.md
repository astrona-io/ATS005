# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module was about the briefing pack: which file adds a variable for whom, and through which door a session must come aboard to see it.

**From [The Ship-Wide Notice Board](./course-01-the-ship-wide-notice-board.md):**

- `/etc/environment` is parsed by `pam_env.so` when a session is set up. It takes bare `KEY=VALUE` lines only: no `export`, no `$VAR` expansion.
- Because PAM reads it, it reaches login and non-login shells alike, ship-wide.

**From [Login Scripts In /etc/profile.d](./course-02-login-scripts-in-profile-d.md):**

- `/etc/profile.d/*.sh` are real scripts, sourced by `/etc/profile`, so `export` and shell logic work.
- `/etc/profile` is read by login shells only, so a non-login shell never sees these variables.

**From [Login Shells, Non-Login Shells And Personal Variables](./course-03-login-and-non-login-shells.md):**

- A login shell reads `/etc/profile`, then the first of `~/.bash_profile`, `~/.bash_login` and `~/.profile`. An interactive non-login shell reads `~/.bashrc`.
- A personal variable goes in the user's own `~/.bash_profile` (login) or `~/.bashrc` (non-login interactive), with `export`.

**From [The Sessions That See None Of This](./course-04-cron-and-systemd.md):**

- Cron jobs and systemd services read no profile files. Give them the variable directly, in the crontab or with `Environment=` or `EnvironmentFile=`.
- Always check from a fresh session of the type that matters.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [System-Wide and Personal Environment Variables Lab](../../../labs/lab-031/docs/question.md) | Login Shells, Non-Login Shells And Personal Variables | set `COMPANY_PROXY` for every user in login and non-login shells, and `EDITOR=vim` for `candidate` only |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Why does <code>export FOO=bar</code> not belong in <code>/etc/environment</code>?</summary>

No shell runs that file. `pam_env.so` parses it and understands only bare `KEY=VALUE` lines.
</details>

<details>
<summary>2. A variable must reach every user in login and non-login shells, and it is a plain value. Which file?</summary>

`/etc/environment`. PAM reads it for every session it sets up.
</details>

<details>
<summary>3. A variable set in <code>/etc/profile.d/team.sh</code> is missing in a new terminal tab. Why?</summary>

The new tab is a non-login shell. `/etc/profile.d/` is sourced by `/etc/profile`, which only login shells read.
</details>

<details>
<summary>4. Which personal files does a login shell read, and in what order?</summary>

The first of `~/.bash_profile`, `~/.bash_login` and `~/.profile` that exists, and only that one.
</details>

<details>
<summary>5. Where do you set <code>EDITOR=vim</code> for one user only, and why does it need <code>export</code>?</summary>

In that user's `~/.bash_profile`. It is a real shell script, so without `export` the variable stays in the shell and never reaches the programs it starts.
</details>

<details>
<summary>6. A systemd service needs a variable. Will a line in <code>/etc/profile.d/</code> help?</summary>

No. systemd starts the service without a login shell. Set the variable with `Environment=` or `EnvironmentFile=` in the unit file.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy env-profiles-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-031
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-030/module-01/playground`. It always starts clean, so nothing you broke carries over.

> *Ask who must see the variable and which door they come through, then pick the file.*
