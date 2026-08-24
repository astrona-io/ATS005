# Chapter 2: Extending PATH Safely

Adding a personal script directory to `$PATH` looks trivial — one `export` line, done. Right up until you place it wrong. Put that directory at the *front* of the search order, and any file inside it with the same name as a real system command now runs *instead* of that command, for anyone whose `PATH` looks there first. A script named `ls`, or worse, `sudo`, sitting in a directory you can write to has just quietly hijacked that command name. This chapter builds `PATH` changes the way the exam — and a security-conscious production environment — actually expects: correctly ordered, and correctly persisted.

> *`PATH` is searched left to right, first match wins — where you put a new directory in that list is a security decision, not just a formatting choice.*

---

## Part I: How the Shell Actually Finds a Command

When you type a bare command name — `ls`, `hello-work`, whatever — the shell does not consult some central registry. It walks the colon-separated list of directories in `$PATH`, from left to right, and runs the **first** executable file it finds with that exact name. It does not check whether a later directory also has a match, and it does not care which one is "the real one" in some abstract sense — first match wins, full stop.

```bash
echo $PATH
type ls
```

`type` is the tool to reach for here, not `which`. `which` only knows how to scan `PATH` for a matching file; `type` is a shell builtin that also understands aliases, functions, and other builtins — the full set of things that could intercept a command name before `PATH` is ever consulted. When you want to know, with certainty, what will actually execute when you type a name, `type` is the more trustworthy answer.

---

## Part II: The Shadowing Trap

Now picture a personal scripts directory, say `~/work`, added to the *front* of `PATH`:

```bash
export PATH="$HOME/work:$PATH"
```

If a file named `ls` exists inside `~/work`, the very next time this user types `ls`, the shell finds `~/work/ls` before it ever reaches `/bin/ls` — because `~/work` now comes first in the search order. The real system `ls` is never even considered. Anyone who can write into `~/work` — including, notably, anything that tricked this user into dropping a file there — has effectively hijacked that command name for this account.

Appending instead of prepending closes this gap entirely:

```bash
export PATH="$PATH:$HOME/work"
```

With this ordering, every existing system directory is searched *first*. A brand-new tool name that doesn't collide with anything still works exactly the same either way — it's only found in `~/work` because nowhere else has it. But an existing command name is never silently overridden, because the shell already found its real match in an earlier directory before it would ever reach `~/work`. Appending is the behavior that adds convenience without introducing a security regression, and it is the correct default any time a task doesn't explicitly ask for override behavior.

---

## Part III: Making It Persistent, in the Right File

A `PATH` change typed directly into a running shell only lives as long as that shell does. To survive new logins and new sessions, it has to be written into a dotfile that a login shell actually reads on startup.

```bash
mkdir -p ~/work
cat > ~/work/hello-work << 'EOF'
#!/bin/bash
echo "running from ~/work"
EOF
chmod +x ~/work/hello-work

echo 'export PATH="$PATH:$HOME/work"' >> ~/.bash_profile
```

`~/.bash_profile` (or `~/.profile`, whichever this account's shell startup actually reads first) is a **login-shell** file — read on a fresh SSH connection or a fresh console login. `~/.bashrc` alone is not a safe substitute here: it is the file read for *interactive non-login* shells, and is not guaranteed to fire for every way a session might actually start. A `PATH` change placed only in `~/.bashrc` can appear to work in a casual test and then mysteriously "not stick" the moment the same user connects a different way.

```bash
source ~/.bash_profile
echo $PATH
hello-work
```

`source` re-reads the dotfile into your *current* shell without waiting for a new login — a shell that was already running when you made the edit has its own private copy of `PATH` from whenever it started, and editing a file on disk does nothing to a process that already has its variables loaded into memory. That's not a bug; it's simply how environment inheritance works. `source` (or a brand-new session) is what actually applies the change to a shell you can test in.

---

## Part IV: Proving the Shadow Never Happens

Persisting the change correctly is only half the job. The task also demands proof that a same-named decoy script never wins over the real system command:

```bash
cat > ~/work/ls << 'EOF'
#!/bin/bash
echo "decoy ls — should never run"
EOF
chmod +x ~/work/ls
hash -r
type ls
ls
```

That `hash -r` is not optional busywork. Bash caches resolved command locations in a hash table the moment it first looks one up, specifically so it doesn't have to re-scan `PATH` on every single invocation. If `ls` was already resolved once earlier in this shell session, the cached entry can mask the true current behavior of `PATH` — giving you a false sense of security (or a false alarm) depending on what was cached. `hash -r` clears that table and forces a genuinely fresh lookup, honoring the append-only ordering: `type ls` should still report the real system binary (`/bin/ls` or `/usr/bin/ls`), because every system directory in `PATH` is searched before `~/work` is ever reached.

```bash
rm ~/work/ls   # clean up the decoy once you've proven the point
```

---

## Chapter Summary

*   `PATH` is searched left to right; the first executable match found wins, full stop.
*   Prepending a user-writable directory is a shadowing risk — a same-named file there intercepts a real command before the system version is ever reached. Appending is the safe default.
*   Persist a personal `PATH` change in a login-shell dotfile (`~/.bash_profile`/`~/.profile`), not `~/.bashrc` alone, so it survives new logins and SSH sessions.
*   A dotfile edit only affects *new* shells (or ones that explicitly `source` it) — the shell you edited from keeps its old, already-loaded `PATH` until you refresh it.
*   `hash -r` clears bash's command-location cache — always run it before trusting a `type`/`which` result immediately after a `PATH` change.

## Self-Check

1. A colleague adds `~/tools` to the front of their `PATH` and later finds that their `grep` command behaves strangely after a teammate committed a script named `grep` into that shared directory. What happened, and how would you fix the ordering?
2. Why does testing a fresh `PATH` change in the very shell you edited the dotfile from risk giving you a misleading result, even if the dotfile itself is correct?
3. After creating a decoy script earlier in `PATH` than the real command, `type` still reports the old, real binary. What single command should you run before trusting that result?
