# Extending PATH Safely

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS005/tree/main/sections/section-030/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-030/module-02/playground
> astrona destroy safe-path-playground
> ```

Adding a personal script directory to `PATH` looks trivial — one `export` line. Right up until you place it wrong. Put that directory at the *front* of the search order and any file in it with the same name as a real command runs *instead* of that command. A script named `ls` — or `sudo` — in a directory you can write to has quietly hijacked that name. This module builds `PATH` changes the way a security-conscious environment expects: correctly ordered, and correctly persisted.

> *`PATH` is searched left to right, first match wins — where a new directory goes in that list is a security decision, not a formatting one.*

## Learning objectives

After this module you can:

- Explain how the shell resolves a bare command name through `PATH` — left to right, first match wins.
- Use `type` instead of `which` to see what a name will actually run, aliases and builtins included.
- Explain why prepending a user-writable directory to `PATH` is a shadowing risk and appending is not.
- Append a directory to `PATH` persistently, in the login-shell dotfile the account actually reads.
- Use `hash -r` to clear bash's command-location cache before trusting a `type` result after a `PATH` change.

## Before you start

You should know that `PATH` is a colon-separated list of directories, what `export` does, how to make a file executable with `chmod +x`, and how to edit a dotfile. `su - candidate` (login shell as that user) is how the checkpoints test a fresh session.

The playground VM already has:

- User `candidate` — an ordinary account; reach it with `su - candidate` from root, no password.
- `/home/candidate/work/helper-tool` — an executable script whose name matches no system command.
- `candidate`'s dotfiles left at the distro defaults; no decoy planted.

Open a shell on it with:

```sh
astrona ssh astro-safe-path-playground
```

Every command block below runs **inside that VM**.

## Where this fits

This is one concrete application of the previous module's question — "which dotfile?" — with a security dimension attached. A `PATH` entry in the wrong *position* is worse than one in the wrong *file*: it can let a directory a user (or an attacker who fooled that user) can write to override a real command, including `sudo`. That is the same privilege boundary Section 010's scoped-`sudo` rules protect.

## How the shell finds a command

Type a bare name — `ls`, `helper-tool` — and the shell does not consult a registry. It walks the colon-separated directories in `PATH` left to right and runs the **first** executable file with that exact name. It does not check whether a later directory also matches. First match wins.

The tool to inspect this is `type`, not `which`. `type` is a shell builtin: it reports what a name will actually run, and it also knows about aliases, shell functions, and other builtins — the things that intercept a name *before* `PATH` is consulted. `which` only scans `PATH` and misses all of that. When you need certainty about what executes, `type` is the trustworthy answer.

> [!TIP]
> **Try it — the search path, and what resolves right now**
>
> ```sh
> su - candidate -c 'echo "$PATH"; type ls; type helper-tool'
> ```
>
> Expect something like:
>
> ```text
> /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
> ls is aliased to `ls --color=auto'
> bash: type: helper-tool: not found
> ```
>
> `ls` resolves through an alias first (a stock Ubuntu shell sets one). `helper-tool` is "not found" — `~/work` is not on `PATH` yet, so its name means nothing. That is the starting point.

## The shadowing trap

Put a personal scripts directory — `~/work` — at the *front* of `PATH`:

```sh
export PATH="$HOME/work:$PATH"
```

If a file named `ls` exists in `~/work`, the next `ls` finds `~/work/ls` before it reaches `/bin/ls`, because `~/work` now comes first. The real `ls` is never considered. Anyone who can write into `~/work` — including anything that tricked the user into saving a file there — has hijacked that command name for the account.

> [!TIP]
> **Try it — a decoy wins when the directory is prepended**
>
> ```sh
> su - candidate
> export PATH="$HOME/work:$PATH"
> printf '#!/bin/bash\necho "decoy ls ran"\n' > ~/work/ls && chmod +x ~/work/ls
> hash -r
> type ls
> ls
> exit
> ```
>
> Expect something like:
>
> ```text
> /home/candidate/work/ls
> decoy ls ran
> ```
>
> With `~/work` first, `type ls` now points at the decoy and running `ls` executes it. (`hash -r` is explained shortly — it forces a fresh lookup.) The real `ls` is still on disk; the shell just never gets to it.

## Appending closes the gap

Reverse the order — directory last:

```sh
export PATH="$PATH:$HOME/work"
```

Now every system directory is searched first. A genuinely new tool name still works — it is found in `~/work` only because nowhere earlier has it. But an existing command name is never overridden, because its real match is found in an earlier directory before the search ever reaches `~/work`. Appending adds the convenience without the security regression; it is the correct default unless a task explicitly asks for override behaviour.

> [!TIP]
> **Try it — appended: real command wins, new tool still found**
>
> ```sh
> su - candidate
> export PATH="$PATH:$HOME/work"
> hash -r
> type ls
> type helper-tool
> helper-tool
> exit
> ```
>
> Expect something like:
>
> ```text
> ls is aliased to `ls --color=auto'
> helper-tool is /home/candidate/work/helper-tool
> helper-tool running from ~/work
> ```
>
> `ls` still resolves ahead of `~/work` (the decoy from the previous checkpoint is now last in the search order and loses). `helper-tool`, which collides with nothing, resolves in `~/work` and runs. Both properties at once — that is why append is the safe default.

## Making it persistent, in the right file

A `PATH` change typed into a running shell lasts only as long as that shell. To survive new logins it must go in a dotfile a **login shell** reads at startup:

```sh
echo 'export PATH="$PATH:$HOME/work"' >> /home/candidate/.profile
```

Use whichever login-shell file the account actually reads *first*: bash checks `~/.bash_profile`, then `~/.bash_login`, then `~/.profile`, and reads only the first that exists. A stock Ubuntu account has just `~/.profile`. `~/.bashrc` alone is not a safe substitute — it is read for *interactive non-login* shells and is not guaranteed to fire for every way a session starts, so a `PATH` line placed only there can pass a casual test and then "not stick" when the user connects differently.

After editing, `source` the file into your current shell to test without a full re-login — a shell that was already running has its own in-memory copy of `PATH` from when it started, and editing a file on disk does nothing to it. A brand-new session is the more rigorous proof.

> [!TIP]
> **Try it — the change survives a fresh login**
>
> ```sh
> echo 'export PATH="$PATH:$HOME/work"' >> /home/candidate/.profile
> su - candidate -c 'type helper-tool; helper-tool'
> ```
>
> Expect something like:
>
> ```text
> helper-tool is /home/candidate/work/helper-tool
> helper-tool running from ~/work
> ```
>
> `su - candidate` is a fresh login shell — it read `~/.profile`, which now appends `~/work`, so `helper-tool` resolves by name with no `export` typed in this session.

## The command-location cache — `hash -r`

Bash caches resolved command paths in a hash table the first time it looks each one up, so it does not re-scan `PATH` on every invocation. That cache can mask a `PATH` change: if `ls` was already resolved earlier in a shell, `type ls` may keep reporting the old location even after `PATH` changed. `hash` is the builtin that manages this table; `hash -r` (**r**eset) clears it and forces a fresh lookup.

> [!TIP]
> **Try it — the cache hides a change until you clear it**
>
> ```sh
> su - candidate
> export PATH="$HOME/work:$PATH"
> ls >/dev/null
> printf '#!/bin/bash\necho "decoy"\n' > ~/work/ls && chmod +x ~/work/ls
> type ls
> hash -r
> type ls
> exit
> ```
>
> Expect something like:
>
> ```text
> ls is hashed (/usr/bin/ls)
> ls is /home/candidate/work/ls
> ```
>
> The first `type ls` still shows the cached `/usr/bin/ls` even though `~/work/ls` now exists earlier in `PATH`. After `hash -r`, the lookup is redone and `type` reports the decoy. Always run `hash -r` before trusting a `type` or `which` result taken right after a `PATH` edit.

> [!WARNING]
> **Common pitfalls — extending PATH**
>
> - Prepending a writable directory (`$HOME/work:$PATH`) — a same-named file there shadows a real command, `sudo` included. Append (`$PATH:$HOME/work`) unless override is explicitly required.
> - Persisting the line in `~/.bashrc` only — that is the non-login file. Use the account's login-shell file (`~/.profile` on stock Ubuntu) so it survives every login path.
> - Testing in the shell you edited — it holds its own `PATH` from startup. `source` the file or open a new session.
> - Trusting `type` / `which` right after a `PATH` change — bash may be answering from its cache. `hash -r` first.

## Section recap

The shell searches `PATH` left to right and runs the first match, so appending a personal directory is safe and prepending a writable one is a shadowing risk. Persist the append in the login-shell dotfile the account actually reads, verify from a fresh session, and clear bash's cache with `hash -r` before trusting a post-change lookup.
