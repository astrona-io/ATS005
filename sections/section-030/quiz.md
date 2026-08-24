# Section 030 Knowledge Check: Shell Environment & PATH

Test your understanding of environment file placement, login-versus-non-login shell behavior, and safe PATH extension.

---

## Scenario-Based Questions

### Question 1
Your infrastructure team needs `COMPANY_PROXY=http://proxy.internal:3128` available to every user, for both login **and** non-login interactive shells, without editing any individual user's dotfiles. Which mechanism should you use?
*   **A)** Add `export COMPANY_PROXY="http://proxy.internal:3128"` to a new script under `/etc/profile.d/`.
*   **B)** Add a plain `COMPANY_PROXY=http://proxy.internal:3128` line to `/etc/environment`.
*   **C)** Add `export COMPANY_PROXY="http://proxy.internal:3128"` to `/etc/bash.bashrc`.
*   **D)** Add the variable to each existing user's `~/.bashrc` with a loop.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `/etc/environment` is parsed by `pam_env.so` at session establishment time, independent of which (if any) shell startup file later runs. That makes it the one mechanism that reaches both login and non-login interactive shells uniformly, system-wide, without touching a single per-user dotfile.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because `/etc/profile.d/*.sh` scripts are only sourced by `/etc/profile`, which fires for **login shells only** — a non-login interactive shell (e.g., a new terminal tab in an already-authenticated session) never reads it.
    *   *Option C* is incorrect because, while `/etc/bash.bashrc` does reach non-login interactive shells on some distributions, it is bash-specific and not the standard, documented, PAM-level mechanism the exam expects for a system-wide, shell-agnostic variable.
    *   *Option D* is incorrect because it directly violates "without editing any individual user's dotfiles," and doesn't apply to accounts created afterward.
</details>

---

### Question 2
You write `export FOO=bar` as a line inside `/etc/environment` and expect it to behave like a normal shell export. What actually happens?
*   **A)** It works exactly like `export` in a shell script, because `/etc/environment` is sourced by `/etc/profile`.
*   **B)** `/etc/environment` is parsed, not executed — it has no concept of `export`, so the line is not interpreted as a shell export statement at all.
*   **C)** The system throws a fatal boot error because `/etc/environment` cannot contain the word `export`.
*   **D)** It works, but only for the root user's shell.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `/etc/environment` is read and parsed by the PAM module `pam_env.so`, not sourced by any shell. Its grammar is a bare `KEY=VALUE` (optionally quoted) pair per line — it has no `export` keyword, no `$VARNAME` expansion, and no command substitution. Writing `export FOO=bar` does not produce the expected variable; the line simply isn't parsed the way a real shell script would interpret it.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because `/etc/environment` is never sourced by `/etc/profile` — that's what `/etc/profile.d/*.sh` scripts are for, which is a distinct mechanism.
    *   *Option C* is incorrect because there is no such fatal-error behavior; the line is simply parsed incorrectly, not rejected outright.
    *   *Option D* is incorrect because `/etc/environment` is not scoped to any particular user in the first place.
</details>

---

### Question 3
A user sets `EDITOR=vim` in their own `~/.bash_profile` and confirms it works over a fresh SSH login. They then report that a cron job they scheduled for the same account doesn't seem to have `EDITOR` set at all. Why?
*   **A)** Cron jobs run as root by default, so a personal user variable never applies.
*   **B)** Cron does not start a login shell and does not source `~/.bash_profile` — its own environment is minimal and independent of shell dotfiles entirely.
*   **C)** `EDITOR` must be set with `declare -x` instead of `export` to be visible to cron.
*   **D)** `~/.bash_profile` only applies to the first login of the day; subsequent sessions, including cron, don't re-read it.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Cron does not start a login shell and does not source `~/.bash_profile`, `~/.profile`, or any other shell startup file. Its environment is minimal and mostly hardcoded (`SHELL`, `PATH`, `HOME`, `LOGNAME` in most implementations). A cron job that genuinely needs `EDITOR` must have it set explicitly inside the crontab itself.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because cron jobs run as whichever user's crontab they belong to, not root by default, and the reasoning about "never applies" is the wrong mechanism regardless.
    *   *Option C* is incorrect because `export` is the correct and sufficient way to mark a shell variable for child-process inheritance — the actual issue is that the file is never read at all in cron's context.
    *   *Option D* is incorrect — there's no such "first login of the day" behavior for dotfile sourcing.
</details>

---

### Question 4
User `candidate` wants their personal `~/work` scripts directory added to `PATH` so their tools run by name, without risking that a file dropped into `~/work` could ever override an existing system command. Which change satisfies this?
*   **A)** `export PATH="$HOME/work:$PATH"` in `~/.bash_profile`.
*   **B)** `export PATH="$PATH:$HOME/work"` in `~/.bash_profile`.
*   **C)** `export PATH="$HOME/work:$PATH"` in `~/.bashrc`.
*   **D)** `alias work='cd ~/work'` in `~/.bash_profile`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Appending `$HOME/work` after the existing `$PATH` means every current system directory is searched first. An existing command name is never shadowed, because the shell finds its real match earlier in the search order before it would ever reach `~/work`. Placing it in `~/.bash_profile` persists the change across fresh login shells and SSH sessions.
*   **Why others are incorrect:**
    *   *Options A and C* both prepend `~/work` ahead of the system directories, meaning any file placed there with the name of an existing command (e.g., `ls`) would run instead of the real one — a shadowing/privilege risk, not a safe default.
    *   *Option D* doesn't add `~/work` to `PATH` at all; it just defines a navigation shortcut and does nothing for running tools by name.
</details>

---

### Question 5
Immediately after appending `~/work` to `PATH` and creating a decoy script named `ls` inside it, you run `type ls` in the same shell session and it still reports the real system `/bin/ls` — even before you've done anything else. What should you do before trusting that this proves the decoy is harmless?
*   **A)** Nothing further is needed; the result already proves the ordering is correct.
*   **B)** Run `hash -r` to clear bash's cached command-location table, then re-run `type ls`, since a previously-resolved command can stay cached regardless of the current PATH order.
*   **C)** Restart the entire virtual machine to force a PATH re-scan.
*   **D)** Run `which -a ls` instead, since `which` is more authoritative than `type`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Bash caches resolved command locations in a hash table the first time it looks one up, precisely to avoid rescanning `PATH` on every invocation. If `ls` was already resolved earlier in this same shell session, the cached entry can make `type`/`which` appear correct regardless of what a newly created earlier-in-PATH script would actually do on a fresh lookup. `hash -r` clears that cache, forcing a genuine re-search that reflects the real current PATH ordering.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because a cached result can mask the true behavior — the test isn't conclusive without clearing the hash table first.
    *   *Option C* is incorrect because a full VM restart is unnecessary; `hash -r` accomplishes the same re-scan for the current shell instantly.
    *   *Option D* is incorrect because `which` does not understand bash's own hash cache or builtins/functions the way `type` does, and switching tools doesn't address the caching concern at all.
</details>
