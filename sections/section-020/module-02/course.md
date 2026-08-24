# Chapter 2: PAM Resource Limits — Making a Restriction Actually Stick

A runaway process forking itself into oblivion is one of the oldest ways to take down a shared server, and the reflex fix everyone reaches for first — "just cap it with `ulimit`" — is right in spirit and wrong in execution the moment it's bolted onto a single user's `.bashrc`. In this chapter we build the restriction the way the exam (and production reality) actually expects: through `/etc/security/limits.conf`, enforced globally by a PAM module, regardless of how the session was ever started.

> *If a resource limit only works when a user logs in "the normal way," it isn't actually enforced — PAM is what makes a limit apply everywhere.*

---

## Part I: Why a `.bashrc` Fix Isn't a Fix

Imagine a coworker already tried to solve a runaway-process problem for a user named `jackie`, by adding a line to her `.bashrc`:

```bash
ulimit -Sp 150
```

This looks reasonable. It even works — the next time jackie opens an interactive shell, her process count is capped at 150. The trouble is in the word *interactive*. `.bashrc` is sourced specifically for interactive, non-login shells — roughly, "you're already logged in somehow, and a new shell is being spawned interactively," like opening a second terminal tab inside an existing SSH session.

That description quietly excludes an enormous number of paths a user's processes can actually start from:

- A cron job running as jackie
- A non-interactive remote command: `ssh web-srv1 somecommand`
- Many systemd-launched user sessions
- `su -` in some configurations, depending on shell and distro defaults

None of these source `.bashrc`. The restriction has a hole exactly where a scripted or automated process — the kind most likely to fork excessively in the first place — would go completely unrestricted. A limit with a hole in it isn't a soft version of the real thing; it's a different, weaker mechanism that happens to look similar in the one case anyone tested it.

There's a second, subtler problem even within the cases `.bashrc` *does* cover: the coworker only set a **soft** limit. A soft limit is the currently enforced value, but any unprivileged user can raise their own soft limit back up, any time, as long as it stays under the hard ceiling. `ulimit -Sp 150` in `.bashrc` doesn't stop jackie's own shell from immediately running `ulimit -Sp 500` right after login. The real backstop — the value a non-root user cannot exceed under any circumstance — is the **hard** limit, and the coworker never touched it.

---

## Part II: Finding the Number You Actually Need

Before replacing anything, the task requires reusing jackie's *currently effective* soft limit as the new hard limit — not a guess, not the number in the `.bashrc` line taken at face value (it might be stale), the actual live value.

```bash
sudo -u jackie -i ulimit -Sp
```

`sudo -u jackie -i` opens an interactive login shell as jackie, which sources her startup files and reports her real, currently-active soft `nproc` limit as a plain integer.

As a cross-check that doesn't depend on shell startup files at all, if jackie has any running process:

```bash
pid=$(pgrep -u jackie | head -1)
sudo prlimit --pid "$pid" --nproc
```

`prlimit` reads a limit directly from the kernel for an arbitrary PID (with permission) — it doesn't care what shell, if any, launched that process, which makes it the more trustworthy source when you want to double-check a number before writing it into a config file that will govern the account going forward.

---

## Part III: The Real Mechanism — `limits.conf` and `pam_limits.so`

The proper fix lives in `/etc/security/limits.conf` (or, better, an isolated drop-in file under `/etc/security/limits.d/`), following a strict four-column syntax:

```text
<domain> <type> <item> <value>
```

For jackie, using the number discovered in Part II:

```bash
sudo vi /etc/security/limits.d/jackie-nproc.conf
```

```text
jackie hard nproc 150
```

- **domain** — who this rule applies to. A bare username (`jackie`), a group with an `@` prefix (`@operators`), or a wildcard (`*`) for everyone.
- **type** — `soft` or `hard`. `hard` is the actual ceiling; a plain user cannot raise it.
- **item** — what's being limited. `nproc` (max processes), `maxlogins` (concurrent sessions), `fsize`, `nofile`, and others — each one a specific resource `pam_limits.so` knows how to enforce.
- **value** — the number.

A drop-in under `/etc/security/limits.d/` rather than a hand-edit of the monolithic `limits.conf` keeps this change isolated: easy to find, easy to review, easy to remove later without hunting through a shared file for one line among dozens — the identical reasoning behind `/etc/sudoers.d/` drop-ins for sudo rules.

None of this matters, however, unless one specific PAM module is actually wired into the login path being used:

```bash
grep -n pam_limits /etc/pam.d/common-session /etc/pam.d/login /etc/pam.d/sshd 2>/dev/null
```

Expected, somewhere in the relevant chain:

```text
session required pam_limits.so
```

This is the detail almost everyone forgets to check, and it is the single most common reason a perfectly-written `limits.conf` entry appears to do absolutely nothing: `pam_limits.so` is the module that actually *reads* `limits.conf`/`limits.d` and applies it, at session-open time, for whatever PAM service stack it's listed in. If it's missing or commented out for the service governing jackie's login (interactive SSH, `su -`, whatever the task specifies), every line in every `limits.conf` drop-in on the system is configured correctly and enforced by nothing. `limits.conf` is data; `pam_limits.so` is the code that reads it — without the second, the first is inert.

Editing a PAM stack is one of the highest-risk categories of change on the exam. Keep your current root/sudo session open while testing any PAM or limits change, and confirm from a *second*, fresh session — `pam_limits.so` only applies its rules at session start, so an already-open shell (including the one you're editing from) will never reflect the new limit no matter how correct the config is.

Once the proper mechanism is confirmed live, the old `.bashrc` hack should be removed, not left in place:

```bash
sudo sed -i '/ulimit -Sp/d' /home/jackie/.bashrc
```

Leaving it wouldn't necessarily break anything outright, but it is redundant at best, and if it ever disagrees with the new `limits.conf` entry, it could re-narrow jackie's soft limit unexpectedly below what the proper configuration now intends — a confusing double-restriction with two different sources of truth.

---

## Part IV: Restricting a Whole Group — `maxlogins`

The second half of this kind of task is usually group-scoped rather than user-scoped. To cap every member of an `operators` group to a single concurrent login session:

```bash
getent group operators
```

Always check group membership before restricting logins — you don't want to discover, after the fact, that someone in that group legitimately needs simultaneous sessions.

```bash
sudo vi /etc/security/limits.d/operators-maxlogins.conf
```

```text
@operators hard maxlogins 1
```

The `@` prefix is the group-domain syntax — this line applies individually to every current and future member of `operators`, not as one shared pool of logins split between them. `maxlogins` is a `pam_limits.so`-specific item (unlike `nproc`, it isn't a raw kernel `rlimit`) — it counts concurrent login *sessions* for members of the domain and refuses a new one past the configured ceiling. It relies on exactly the same `pam_limits.so` session line already confirmed in Part III; no separate PAM wiring is needed just because the item changed.

Some practice environments genuinely cannot exercise a live second-login test from within the grading session itself. When that's the case, the deliverable is the configuration verified by inspection — don't burn time trying to force a live test the environment was never built to support, and don't conclude the configuration is wrong just because an interactive re-test isn't possible from where you're sitting.

---

## Chapter Summary

- A `.bashrc` `ulimit` line only ever fires for interactive, non-login shells — cron jobs, non-interactive SSH commands, and many systemd session types never source it, leaving exactly the automated paths most likely to misbehave completely unrestricted.
- `limits.conf` syntax is always `<domain> <type> <item> <value>`; `@groupname` targets every member of a group instead of one user.
- Before replacing a limit, discover the *current* effective value with `ulimit -Sp` (in the user's own session) or `prlimit --pid <pid>` (from anywhere) — don't guess or trust a stale dotfile line.
- `pam_limits.so` must be present in the `session` stack of whatever PAM service governs the login path in question, or every `limits.conf`/`limits.d` entry on the system is inert — this is the most commonly missed step.
- `maxlogins` is a `pam_limits.so` item like any other, enforced by the same session hook as `nproc` — no extra PAM wiring beyond confirming that hook exists.
- A limit only applies at session *start* — an already-open session never picks up a change retroactively; always test from a fresh session.

## Self-Check

1. Why does a `ulimit -Sp` line in `.bashrc` fail to protect against a cron job or a non-interactive `ssh host command` run by the same user?
2. You've written a perfectly correct `limits.conf` entry, but the user's hard limit still shows as unlimited after a fresh login. What's the first thing to check, and why?
3. Why is `@operators hard maxlogins 1` a per-user rule for each group member rather than a single shared login slot for the whole group?
