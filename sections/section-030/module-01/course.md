# Chapter 1: The Forest of Environment Files

Every Linux distribution ships a small forest of files that are each capable of setting an environment variable: `/etc/environment`, `/etc/profile`, every script under `/etc/profile.d/`, and then a whole personal layer per user — `~/.profile`, `~/.bash_profile`, `~/.bash_login`, `~/.bashrc`. At first glance this looks like redundant clutter. In practice, every one of these files exists to answer a different question: *who* does this variable apply to, and *what kind of session* is it allowed to reach?

Get the wrong file and the failure is not vague. It is exact. A variable set in the wrong place is not "sometimes broken" — it is precisely and predictably absent from every session type that never reads that file. It works perfectly over your SSH connection and vanishes without a trace inside a cron job, a systemd unit, or a colleague's brand-new terminal tab. This chapter builds the mental map that keeps that from happening.

---

## Part I: A File That Isn't a Script

Let's start with the most commonly misunderstood file on this list: `/etc/environment`.

If you open it, it looks exactly like a shell script waiting to happen:

```text
COMPANY_PROXY=http://proxy.internal:3128
```

Every instinct you have as a shell user wants to reach for `export`. Resist that instinct. `/etc/environment` is not executed by any shell at all — it is **parsed** by a PAM module called `pam_env.so`, at the moment a session is established, before any shell startup file even runs. Because it is parsed rather than interpreted, it understands exactly one grammar: a bare `KEY=VALUE` pair per line, optionally quoted if the value contains whitespace. It has no concept of `export`, no `$OTHER_VARIABLE` expansion, and no command substitution. Write `export FOO=bar` in this file and you have not exported anything — you have simply written a line that doesn't parse the way you expect.

This distinction matters far beyond syntax pedantry. Because `pam_env` operates at the PAM session layer rather than inside a particular shell's startup sequence, `/etc/environment` is read for **any** session PAM is involved in establishing — regardless of whether that session turns out to be a login shell or a non-login interactive shell. This is the one mechanism on this entire list that doesn't care about the login/non-login distinction we're about to cover. That makes it the correct tool whenever a requirement spans both shell types system-wide, and the *wrong* tool the moment you need real shell logic — conditionals, command substitution, sourcing other files — none of which `/etc/environment` can express.

```bash
sudo tee -a /etc/environment <<'EOF'
COMPANY_PROXY=http://proxy.internal:3128
EOF
```

One critical caveat: PAM reads this file once, at session establishment. It is not a live, continuously-watched configuration. A shell that was already running before you edited it has no reason to notice the change — there is no "reload" for PAM-parsed environment short of starting an entirely new session.

---

## Part II: When You Actually Need a Script — `/etc/profile.d/`

Suppose the requirement were slightly different: not "reach every shell type," but "support real shell syntax — a conditional, a computed value — and apply it system-wide." That's what `/etc/profile.d/*.sh` is for.

```bash
sudo tee /etc/profile.d/company-proxy.sh <<'EOF'
export COMPANY_PROXY="http://proxy.internal:3128"
EOF
sudo chmod 644 /etc/profile.d/company-proxy.sh
```

Every `.sh` file dropped into `/etc/profile.d/` is genuinely `source`d by `/etc/profile` as part of that file's own execution. Because it's sourced rather than parsed, it supports everything a real script supports: `export`, conditionals, calling other commands.

The catch is right there in the sentence: it is sourced by `/etc/profile`, and `/etc/profile` is only read for **login shells**. This is the gap that makes `/etc/profile.d/` the wrong primary choice for a "both login and non-login" requirement, and it's exactly why `/etc/environment` was the right call in Part I.

---

## Part III: Login Shell or Not? The Distinction That Decides Everything

Here is the fork in the road that every dotfile decision hinges on: is the shell being started a **login shell**, or an **interactive non-login shell**?

A login shell is one started as if the user just authenticated — a fresh SSH connection with no command attached, or a console/tty login. On startup, bash reads `/etc/profile` (and everything it sources, including `/etc/profile.d/*.sh`), then looks for the *first* of `~/.bash_profile`, `~/.bash_login`, or `~/.profile` that exists, and reads only that one.

An interactive non-login shell is what you get opening a new terminal tab inside a desktop session you're already logged into, or simply typing `bash` from inside an existing shell. That path never touches `/etc/profile` or `~/.bash_profile` at all — it reads `~/.bashrc` instead.

```text
Login shell path:        /etc/profile → /etc/profile.d/*.sh → ~/.bash_profile (first match)
Non-login interactive:   ~/.bashrc only
```

This is why a variable that "worked when I SSH'd in" can vanish the moment a colleague opens a second terminal tab in their already-running desktop session — those are two different startup paths, reading two different sets of files, and neither one implies the other.

---

## Part IV: A Personal Variable, Placed Correctly

Now apply this to a personal preference — say, one user wants `EDITOR=vim` set for themselves, and nobody else.

```bash
echo 'export EDITOR=vim' >> ~/.bash_profile
```

Two decisions are baked into this one line. First, it touches *only* this user's own file — no system-wide file is involved, so no other account is affected. Second, `~/.bash_profile` is a real shell script (unlike `/etc/environment`), so `export` is not optional here — without it, `EDITOR` would exist only inside that one shell process and never propagate to any command or child process the user runs.

```bash
source ~/.bash_profile
echo "$EDITOR"
```

`source` re-reads the file into your *current* shell, which is a convenient way to test without a full logout/login cycle — though a genuinely fresh session remains the more rigorous proof, which brings us to the next section.

---

## Part V: Proving It, Not Assuming It

The single most common mistake at this stage is testing a system-wide or per-user change from the same shell you used to make the edit — and concluding it "doesn't work" when really you just never gave it a fresh session to read from.

```bash
ssh terminal 'env | grep -E "COMPANY_PROXY|EDITOR"'
```

That's a genuine login shell — `/etc/environment` should show up regardless of what dotfile you used, and `EDITOR` should show up if the connecting user is the one whose `~/.bash_profile` you edited.

```bash
bash --norc -c 'env | grep COMPANY_PROXY'   # PAM-level: still present
bash -c 'echo $EDITOR'                       # .bash_profile never sourced here: expect empty
```

The second command is deliberately a non-interactive, non-login invocation — it skips both `/etc/profile` and `~/.bash_profile` entirely, so an empty result there is not a bug, it's the correct and expected behavior for that startup path.

---

## Part VI: The Sessions That See None of This

Two extremely common execution contexts deserve a direct warning: cron and systemd.

A cron job does not start a login shell and does not source any of the files covered in this chapter. Its environment is minimal and mostly hardcoded (`SHELL`, `PATH`, `HOME`, `LOGNAME` in most implementations). If a scheduled job genuinely needs `COMPANY_PROXY`, the correct fix is to set it explicitly as a line inside that crontab, not to hope it inherits from a profile file it never reads.

systemd services are started directly by systemd — not through any login shell, and not through PAM's `pam_env` unless that specific service's PAM stack is configured to invoke it (rare, and distro-dependent). A unit that needs an environment variable gets it via `Environment=` or `EnvironmentFile=` directives in the unit file itself.

---

## Chapter Summary

*   `/etc/environment` is parsed by `pam_env.so` at session establishment — plain `KEY=VALUE`, no `export`, no expansion — and is the one mechanism that reaches both login and non-login interactive shells uniformly, system-wide.
*   `/etc/profile.d/*.sh` files are real, sourced shell scripts, but only for **login shells** — a non-login interactive shell never touches them.
*   A personal preference belongs in the requesting user's own `~/.bash_profile` (login-shell) or `~/.bashrc` (non-login interactive), never in a system-wide file.
*   Cron and systemd source none of this by default — a job or unit that needs a variable must be given it explicitly.
*   Always verify environment changes from a genuinely fresh session of the relevant type — a stale, already-running shell will lie to you about whether the fix worked.

## Self-Check

1. Why does writing `export FOO=bar` inside `/etc/environment` not behave the way it would in a shell script?
2. A variable is set correctly in `/etc/profile.d/network.sh`, but a user reports it's missing when they open a second terminal tab in their existing desktop session. What's the most likely explanation?
3. Why is `bash --norc -c '...'` a fair way to demonstrate `/etc/environment`'s reach, while `bash -c '...'` is a fair way to demonstrate that `~/.bash_profile` was *not* read?
