# PAM Resource Limits — Making a Restriction Actually Stick

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS005/tree/main/sections/section-020/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-020/module-02/playground
> astrona destroy pam-limits-playground
> ```

A process forking itself into oblivion is one of the oldest ways to bring down a shared server, and the reflex fix — "cap it with `ulimit`" — is right in spirit and wrong in execution the moment it is bolted onto one user's `.bashrc`. This module builds the restriction the way it actually holds: an entry in `/etc/security/limits.conf`, applied at login by a PAM module, no matter how the session started.

> *If a resource limit only works when a user logs in "the normal way," it is not really enforced — `pam_limits.so` is what makes a limit apply everywhere.*

## Learning objectives

After this module you can:

- Explain why a `.bashrc` `ulimit` line leaves cron jobs and non-interactive `ssh host cmd` runs unrestricted.
- Distinguish a soft limit from a hard limit, and say which one a non-root user cannot raise.
- Read a user's live effective limit with `ulimit` in their own session or `prlimit --pid` from anywhere.
- Write a hard `nproc` limit as an `/etc/security/limits.d/` drop-in in the four-column syntax.
- Check that `pam_limits.so` is in the PAM `session` stack for the login path, and explain why the config is inert without it.
- Cap concurrent logins for a whole group with `@group hard maxlogins`.

## Before you start

You should know what a shell startup file is (`~/.bashrc` and friends), be able to run a command as another user with `sudo -u`, and edit a file as root. "PAM" here just means the stack of modules the system runs when a session opens — you will inspect one line of it, not rewrite it.

The playground VM already has:

- `jackie` — with `ulimit -Su 150` appended to `~/.bashrc` (the fragile "fix"), and a long-running process (`systemd-run` unit `jackie-sleeper`) so `prlimit` has a target.
- Group `operators` with members `ops-anna`, `ops-ben`, `ops-carl`.
- `pam_limits.so` already enabled in `/etc/pam.d/common-session`.

Open a shell on it with:

```sh
astrona ssh astro-pam-limits-playground
```

Every command block below runs **inside that VM**. `ulimit` here is the shell builtin that reads and sets the calling process's resource limits; the flags that matter are `-u` (max user processes, the `nproc` limit), `-S` (operate on the *soft* value), and `-H` (the *hard* value).

## Where this fits

The aging fields from Section 010 Module 3 and the limits here are both enforced by PAM at the moment a session opens — same framework, different modules (`pam_unix`, `pam_limits`). That is also why both share a failure mode: an already-open shell never reflects the change, because the module only runs at session *start*. The ACL half of this section is a different mechanism but the same lesson — a fix that looks right (`ulimit` in `.bashrc`) can have a silent hole exactly where it matters.

## Why a `.bashrc` fix is not a fix

Say a coworker capped `jackie`'s runaway forks by adding one line to `~/.bashrc`:

```text
ulimit -Su 150
```

It works — the next *interactive* shell jackie opens has its process count capped at 150. The problem is the word *interactive*. `~/.bashrc` is sourced for interactive non-login shells — "you are already in somehow, and a new shell spawns," like a second terminal tab in an existing SSH session. That excludes:

- a cron job running as jackie,
- a non-interactive remote command: `ssh web-srv1 somecommand`,
- many systemd-launched user sessions,
- `su -` in some configurations.

None of those source `~/.bashrc`. The restriction has a hole exactly where a scripted or automated process — the kind most likely to fork out of control — would run.

There is a second problem even where `.bashrc` *is* read: the coworker set only a **soft** limit. A soft limit is the currently enforced value, but any unprivileged user can raise their own soft limit at will, up to the hard ceiling. The **hard** limit is the real backstop — the value a non-root user cannot exceed under any circumstance — and it was never touched.

> [!TIP]
> **Try it — the hole, and the soft-limit weakness**
>
> ```sh
> tail -n 3 /home/jackie/.bashrc
> sudo -u jackie -i ulimit -Su
> sudo -u jackie bash -c 'ulimit -Su'
> sudo -u jackie -i ulimit -Hu
> ```
>
> Expect something like:
>
> ```text
> # added by a coworker to stop runaway forks (fragile: interactive shells only)
> ulimit -Su 150
> 150
> 14611
> unlimited
> ```
>
> The login-shell path (`-i`) picks up the `.bashrc` line and reports `150`. The plain `bash -c` path — standing in for cron or `ssh host cmd` — never sources `.bashrc` and shows the untouched default (a large number, varies by RAM). And the *hard* limit is still `unlimited`: nothing stops jackie from running `ulimit -Su 500` herself.

## Finding the number you actually need

A real task usually wants jackie's *currently effective* soft limit reused as the new hard limit — the live value, not the possibly-stale number in the dotfile. Read it from her own session:

```sh
sudo -u jackie -i ulimit -Su
```

`sudo -u jackie -i` opens a login shell as jackie, sources her startup files, and reports the active soft `nproc` limit as a plain integer.

As a cross-check that does not depend on shell startup files at all, read it straight from the kernel for one of her processes with `prlimit` (read: *process limit* — it gets or sets the kernel resource limits of a running PID):

```sh
sudo prlimit --pid "$(systemctl show -p MainPID --value jackie-sleeper)" --nproc
```

The inner command just fetches the process ID: `systemctl show -p MainPID --value <unit>` prints one property of a unit (`-p` names it, `--value` prints the bare value with no `MainPID=` prefix), here the PID of the seeded `jackie-sleeper` service. `prlimit` does not care what shell, if any, launched that process — which makes it the more trustworthy source when you are about to write a number into a config file that will govern the account.

> [!TIP]
> **Try it — two independent readings of the same limit**
>
> ```sh
> sudo -u jackie -i ulimit -Su
> sudo prlimit --pid "$(systemctl show -p MainPID --value jackie-sleeper)" --nproc
> ```
>
> Expect something like:
>
> ```text
> 150
> RESOURCE   DESCRIPTION                             SOFT      HARD UNITS
> NPROC      max number of processes                  150 unlimited processes
> ```
>
> The `jackie-sleeper` process was started by systemd, not by an interactive shell, yet `prlimit` still shows its `NPROC` soft value. Both readings agree on `150` — that is the number to carry into `limits.conf`.

## The real mechanism — `limits.conf` and `pam_limits.so`

The proper fix lives in `/etc/security/limits.conf`, or better an isolated drop-in under `/etc/security/limits.d/`, in a strict four-column syntax:

```text
<domain>  <type>  <item>  <value>
```

For jackie, using the number from the previous section:

```text
jackie  hard  nproc  150
```

- **domain** — who the rule applies to. A bare username (`jackie`), a group with `@` (`@operators`), or `*` for everyone.
- **type** — `soft` or `hard`. `hard` is the ceiling a plain user cannot raise.
- **item** — the resource. `nproc` (max processes), `maxlogins` (concurrent sessions), `fsize`, `nofile`, and more — each one something `pam_limits.so` knows how to enforce.
- **value** — the number.

A drop-in under `limits.d/` rather than a hand-edit of the monolithic file keeps the change easy to find, review, and remove later — the same reasoning as `/etc/sudoers.d/` drop-ins.

None of this does anything unless `pam_limits.so` is wired into the login path in use. Check it:

```sh
grep -n pam_limits /etc/pam.d/common-session /etc/pam.d/login /etc/pam.d/sshd 2>/dev/null
```

You want a line like `session required pam_limits.so` somewhere in the relevant chain. This is the most commonly missed step: `pam_limits.so` is the module that actually *reads* `limits.conf` / `limits.d` and applies it at session-open time. If it is missing or commented out for the service governing the login, every `limits.conf` line on the system is correct and enforced by nothing. `limits.conf` is data; `pam_limits.so` is the code that reads it.

> [!TIP]
> **Try it — write the drop-in, confirm from a fresh session**
>
> ```sh
> grep -n pam_limits /etc/pam.d/common-session
> echo 'jackie  hard  nproc  150' | sudo tee /etc/security/limits.d/jackie-nproc.conf
> sudo -u jackie -i ulimit -Hu
> ```
>
> Expect something like:
>
> ```text
> 25:session required                        pam_limits.so
> jackie  hard  nproc  150
> 150
> ```
>
> `pam_limits.so` is present in `common-session`, so the drop-in is live. A **fresh** login shell (`sudo -u jackie -i`) now reports a hard `nproc` of `150` — jackie can no longer raise her soft limit past it. A shell she already had open would still show the old value; `pam_limits.so` only applies at session start.

With the proper mechanism confirmed, the old hack should be removed so there are not two sources of truth:

```sh
sudo sed -i '/ulimit -Su/d' /home/jackie/.bashrc
```

> [!WARNING]
> **Common pitfalls — PAM limits**
>
> - `limits.conf` entry written, limit still not applied — check `pam_limits.so` is in the `session` stack of the *right* PAM service (`sshd`, `login`, `common-session`). Without it the file is inert.
> - Testing from the shell you edited in — the limit only takes effect at session start. Always retest from a new login; keep your current root session open in case a PAM edit goes wrong.
> - Setting only a `soft` limit — a user can raise their own soft limit up to the hard one. The enforceable backstop is `hard`.
> - Trusting the `.bashrc` number — read the live value with `ulimit` or `prlimit` first; the dotfile line may be stale.

## Restricting a whole group — `maxlogins`

The group-scoped half of a task like this caps concurrent sessions. Check membership *first* with `getent` (read: *get entries* — it asks NSS for a database record the same way the system does, so it sees local *and* directory-provided members): you do not want to find out afterward that someone in the group needs simultaneous logins.

```sh
getent group operators
```

Then a drop-in:

```text
@operators  hard  maxlogins  1
```

The `@` prefix is the group-domain syntax — the line applies individually to every current and future member of `operators`, not as one shared pool of logins. `maxlogins` is a `pam_limits.so`-specific item (not a raw kernel `rlimit` like `nproc`): it counts concurrent login *sessions* for members of the domain and refuses a new one past the ceiling. It relies on the same `session` line already confirmed for `nproc` — no extra PAM wiring because the item changed.

> [!TIP]
> **Try it — membership check, then the drop-in**
>
> ```sh
> getent group operators
> printf '@operators  hard  maxlogins  1\n' | sudo tee /etc/security/limits.d/operators-maxlogins.conf
> sudo grep -rn . /etc/security/limits.d/
> ```
>
> Expect something like:
>
> ```text
> operators:x:1005:ops-anna,ops-ben,ops-carl
> @operators  hard  maxlogins  1
> /etc/security/limits.d/jackie-nproc.conf:1:jackie  hard  nproc  150
> /etc/security/limits.d/operators-maxlogins.conf:1:@operators  hard  maxlogins  1
> ```
>
> `getent` lists exactly who the cap will hit. A live "open a second login and watch it bounce" test needs two independent sessions and is not always possible from inside one SSH connection — the config, verified by inspection like the last `grep`, is what you are producing.

## Section recap

You can now tell a soft limit from a hard one, read a live limit with `ulimit` or `prlimit`, write a hard `nproc` cap as a `limits.d` drop-in, confirm `pam_limits.so` is in the session stack that governs the login, and apply a per-member `maxlogins` cap to a group. The rule that ties it together: the limit applies at session start and only if `pam_limits.so` reads it.
