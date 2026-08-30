# The Forest of Environment Files

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS005/tree/main/sections/section-030/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-030/module-01/playground
> astrona destroy env-profiles-playground
> ```

Every Linux distribution ships a small forest of files that can each set an environment variable: `/etc/environment`, `/etc/profile`, everything under `/etc/profile.d/`, and a personal layer per user — `~/.profile`, `~/.bash_profile`, `~/.bash_login`, `~/.bashrc`. It looks like redundant clutter. It is not: each file answers a different pair of questions — *who* does this variable apply to, and *what kind of session* is allowed to see it. Put a variable in the wrong file and the failure is exact and repeatable: it works over your SSH connection and is silently absent from a cron job, a systemd unit, or a colleague's new terminal tab. This module builds the map that prevents that.

## Learning objectives

After this module you can:

- Explain why `/etc/environment` takes only `KEY=VALUE` — no `export`, no expansion — and which layer reads it.
- Choose between `/etc/environment` and `/etc/profile.d/*.sh` based on whether shell logic is needed and which session types must be reached.
- Trace which startup files a login shell reads versus an interactive non-login shell.
- Place a personal variable in the correct per-user dotfile so it affects one account and the right session type.
- Explain why cron jobs and systemd services do not inherit profile variables, and how to give them one.
- Verify an environment change from a fresh session of the right type rather than the shell you edited in.

## Before you start

You should know what an environment variable is, what `export` does in a shell, and how to edit a file as root. It helps to know that `su - <user>` starts a *login* shell as that user and plain `su <user>` starts a *non-login* one — that difference is half of this module.

The playground VM already has:

- Users `candidate` and `otheruser` — ordinary accounts; reach them with `su - candidate` from root, no password.
- `/etc/cron.d/env-probe` — a cron job that writes its environment to `/home/candidate/cron-env.txt` every minute.
- `env-probe.service` — a systemd unit that writes its environment to `/run/env-probe.txt` when started.
- `/etc/environment`, `/etc/profile.d/`, and every dotfile untouched.

Open a shell on it with:

```sh
astrona ssh astro-env-profiles-playground
```

Every command block below runs **inside that VM**, as root unless it says otherwise. `env` with no arguments, used throughout to check results, just prints the calling process's full environment.

## Where this fits

This module is the "which file" half of the section; the next one (safe `PATH` extension) is one specific application of the same decision. The mechanism underneath `/etc/environment` — `pam_env.so` at the PAM session layer — is the same PAM framework that enforces password aging (Section 010) and resource limits (Section 020): configuration read once, when the session is established. Cron and systemd sit outside the shell-profile world entirely, which is why a variable that "works everywhere" in testing can still be missing from a scheduled job.

## A file that is not a script — `/etc/environment`

`/etc/environment` looks like a shell script waiting to happen:

```text
COMPANY_PROXY=http://proxy.internal:3128
```

Every instinct says to add `export`. Resist it. `/etc/environment` is not run by any shell — it is **parsed** by a PAM module, `pam_env.so`, when a session is established, before any shell startup file runs. Parsed, not interpreted, means it understands exactly one grammar: a bare `KEY=VALUE` per line, optionally quoted if the value has whitespace. No `export`, no `$OTHER_VAR` expansion, no command substitution. Write `export FOO=bar` here and you have written a line that simply does not parse the way you meant.

Because `pam_env` runs at the PAM session layer, not inside a shell's startup sequence, `/etc/environment` is read for **any** session PAM establishes — login shell or interactive non-login shell alike. It is the one mechanism here that does not care about that distinction, which makes it right when a plain variable must reach both system-wide, and wrong the moment you need shell logic.

> [!TIP]
> **Try it — one line, both session types**
>
> ```sh
> echo 'COMPANY_PROXY=http://proxy.internal:3128' | sudo tee -a /etc/environment
> su - candidate -c 'echo "login: $COMPANY_PROXY"'
> su candidate -c 'echo "non-login: $COMPANY_PROXY"'
> ```
>
> Expect something like:
>
> ```text
> COMPANY_PROXY=http://proxy.internal:3128
> login: http://proxy.internal:3128
> non-login: http://proxy.internal:3128
> ```
>
> Both `su` forms show the value — `su -` (login) and plain `su` (non-login) both go through PAM, and `pam_env` ran for each. An already-open shell would *not* show it: PAM reads the file once at session start, there is no reload.

## When you need a script — `/etc/profile.d/`

Change the requirement to "support real shell syntax — a conditional, a computed value — system-wide," and `/etc/environment` cannot do it. `/etc/profile.d/*.sh` can:

```sh
sudo tee /etc/profile.d/company-proxy.sh <<'EOF'
export COMPANY_PROXY="http://proxy.internal:3128"
EOF
sudo chmod 644 /etc/profile.d/company-proxy.sh
```

Every `.sh` file in `/etc/profile.d/` is `source`d by `/etc/profile` as part of its execution — so it supports `export`, conditionals, calling other commands, everything a script does. The catch is in that sentence: it is sourced by `/etc/profile`, and `/etc/profile` is read only for **login shells**. That is precisely why `/etc/environment` was the right call for a "both types" requirement and `/etc/profile.d/` is not.

> [!TIP]
> **Try it — a profile.d variable reaches login shells only**
>
> ```sh
> echo 'export TEAM_REGION="eu-west"' | sudo tee /etc/profile.d/team-region.sh
> su - candidate -c 'echo "login: $TEAM_REGION"'
> su candidate -c 'echo "non-login: $TEAM_REGION"'
> ```
>
> Expect something like:
>
> ```text
> export TEAM_REGION="eu-west"
> login: eu-west
> non-login:
> ```
>
> The login shell sourced `/etc/profile` and picked up the drop-in. The non-login shell never touched `/etc/profile`, so the variable is simply absent — not broken, just never read on that path.

## Login shell or not — the distinction that decides everything

Every dotfile decision hinges on one fork: is the shell a **login shell** or an **interactive non-login shell**?

- A **login shell** starts as if the user just authenticated — a fresh SSH connection with no command, a console/tty login, or `su -`. Bash reads `/etc/profile` (and what it sources, including `/etc/profile.d/*.sh`), then the *first* of `~/.bash_profile`, `~/.bash_login`, `~/.profile` that exists — only that one.
- An **interactive non-login shell** is a new terminal tab in an already-logged-in desktop session, or typing `bash` inside an existing shell. It never touches `/etc/profile` or `~/.bash_profile` — it reads `~/.bashrc`.

```text
Login shell:            /etc/profile → /etc/profile.d/*.sh → ~/.bash_profile (first match)
Non-login interactive:  ~/.bashrc only
```

That is why a variable that "worked when I SSH'd in" can vanish when a colleague opens a second terminal tab — two startup paths, two file sets, neither implying the other.

> [!TIP]
> **Try it — watch each path read a different file**
>
> ```sh
> echo 'export MARKER=from-bash_profile' >> /home/candidate/.bash_profile
> echo 'export MARKER=from-bashrc'       >> /home/candidate/.bashrc
> su - candidate -c 'echo "$MARKER"'
> su - candidate -c 'bash -c "echo $MARKER"'
> ```
>
> Expect something like:
>
> ```text
> from-bash_profile
> from-bashrc
> ```
>
> The login shell (`su - candidate`) read `~/.bash_profile`. The child `bash` it spawned is interactive-less and non-login, so it read `~/.bashrc` instead — same account, two files, two values.

## A personal variable, placed correctly

For a preference one user wants and nobody else — say `EDITOR=vim`:

```sh
echo 'export EDITOR=vim' >> /home/candidate/.bash_profile
```

Two decisions are in that line. It touches only this user's file, so no other account is affected. And `~/.bash_profile` is a real shell script, so `export` is required — without it, `EDITOR` would live only in that one shell and never reach a child process.

> [!TIP]
> **Try it — one account, not the others**
>
> ```sh
> su - candidate -c 'echo "candidate: $EDITOR"'
> su - otheruser -c 'echo "otheruser: $EDITOR"'
> ```
>
> Expect something like:
>
> ```text
> candidate: vim
> otheruser:
> ```
>
> `candidate`'s login shell read `candidate`'s `~/.bash_profile`. `otheruser` has no such line in their own dotfiles, so the variable is not set for them — the change is genuinely per-user.

## The sessions that see none of this

Two very common contexts do not read the shell-profile forest at all: **cron** and **systemd**.

A cron job does not start a login shell and does not source `/etc/profile`, `~/.bash_profile`, or `~/.bashrc`. Its environment is minimal — typically just `SHELL`, `PATH`, `HOME`, `LOGNAME`. On Debian and Ubuntu, cron's PAM stack *does* pull in `/etc/environment` (so a variable set there may appear in a cron job on this VM), but that is distro-specific and not true everywhere — do not rely on it. A scheduled job that needs a variable should have it set explicitly in the crontab.

A systemd service is started directly by systemd — no login shell, and no `pam_env` unless that service's PAM stack is specially configured (rare). A unit that needs a variable gets it from `Environment=` or `EnvironmentFile=` in the unit file.

> [!TIP]
> **Try it — what cron and systemd actually inherit**
>
> ```sh
> sudo systemctl start env-probe.service
> grep -E 'COMPANY_PROXY|TEAM_REGION' /run/env-probe.txt || echo "systemd: neither variable"
> sleep 61
> grep -E 'COMPANY_PROXY|TEAM_REGION' /home/candidate/cron-env.txt || echo "cron: neither variable"
> ```
>
> Expect something like:
>
> ```text
> systemd: neither variable
> COMPANY_PROXY=http://proxy.internal:3128
> ```
>
> The systemd unit inherits neither — it is outside both PAM and the shell profiles. The cron job (on this Ubuntu image) shows `COMPANY_PROXY` from `/etc/environment` via cron's PAM stack, but **not** `TEAM_REGION` from `/etc/profile.d/` — cron never sources a profile script. That gap is exactly the mechanism boundary.

> [!WARNING]
> **Common pitfalls — environment files**
>
> - `export FOO=bar` in `/etc/environment` — it is parsed, not run. Use a bare `FOO=bar`; `export` and `$VAR` expansion do nothing there.
> - A variable in `/etc/profile.d/*.sh` "missing" in a new terminal tab — that is a non-login shell; `/etc/profile.d/` is login-only. Use `/etc/environment` for both types, or add it to `~/.bashrc` for the interactive case.
> - Testing from the shell you edited in — dotfiles and `/etc/environment` are read at session start. Test from a fresh `su -`, a new SSH login, or a new tab, as appropriate.
> - Expecting a cron job or systemd unit to inherit a profile variable — give it one explicitly (crontab line, `Environment=` / `EnvironmentFile=`).
> - Putting a personal preference in a system-wide file — it leaks to every account. Personal goes in the user's own `~/.bash_profile` or `~/.bashrc`.

## Section recap

`/etc/environment` is parsed by `pam_env.so` at session establishment — plain `KEY=VALUE`, reaching login and non-login shells alike, system-wide. `/etc/profile.d/*.sh` are real sourced scripts but login-shell only. A personal variable belongs in the user's own `~/.bash_profile` (login) or `~/.bashrc` (non-login interactive). Cron and systemd read none of the profile files; give them the variable directly. And always verify from a fresh session of the type that matters.
