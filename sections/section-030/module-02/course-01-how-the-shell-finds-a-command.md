# How The Shell Finds A Command

Astronaut, when you call a crew member by name, the ship searches its decks in a fixed order and sends the first one it finds. This part shows you that search, the tool that tells you what a name will really run, and how an impostor on an earlier deck takes over a real command.

## The search path

Type a bare name, such as `ls` or `helper-tool`, and the shell does not look it up in a registry. It walks the directories in `PATH` from left to right.

### See the search path and what resolves now

Print `candidate`'s `PATH` and ask what two names resolve to:

<!-- astrona:playground:renew -->

```sh
su - candidate -c 'echo "$PATH"; type ls; type helper-tool'
```

Expect something like:

```text
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
ls is aliased to `ls --color=auto'
bash: type: helper-tool: not found
```

`ls` resolves through an alias first (a stock Ubuntu shell sets one). `helper-tool` is "not found", because `~/work` is not on `PATH` yet, so its name means nothing. That is the starting point.

### First match wins

The shell runs the **first** executable file with that exact name, in the first directory that has one. It does not check whether a later directory also has a match.

The tool to inspect this is `type`, not `which`. `type` is built into the shell: it reports what a name will really run, and it also knows about aliases, shell functions and other built-in commands, the things that catch a name *before* `PATH` is searched. `which` only scans `PATH` and misses all of that. When you need certainty about what runs, trust `type`.

## The shadowing trap

Now put a personal scripts directory, `~/work`, at the *front* of `PATH`:

```sh
export PATH="$HOME/work:$PATH"
```

If a file named `ls` exists in `~/work`, the next `ls` finds `~/work/ls` before it reaches `/bin/ls`, because `~/work` now comes first. The real `ls` is never considered. Anyone who can write into `~/work`, including anything that tricked the user into saving a file there, has taken over that command name for the account.

### A decoy wins when the directory comes first

Open a shell as `candidate`, put `~/work` first, plant a decoy `ls`, clear the cache, and look:

```sh
su - candidate
export PATH="$HOME/work:$PATH"
printf '#!/bin/bash\necho "decoy ls ran"\n' > ~/work/ls && chmod +x ~/work/ls
hash -r
type ls
ls
exit
```

Expect something like:

```text
/home/candidate/work/ls
decoy ls ran
```

With `~/work` first, `type ls` points at the decoy, and running `ls` runs it. `hash -r` makes the shell forget the locations it remembered, so the lookup is fresh. The real `ls` is still on disk; the shell just never gets to it.

If your shell has an alias for `ls`, `type ls` reports the alias first, and the alias then runs whichever `ls` comes first in `PATH`. `type -P ls` shows only the file that the `PATH` search finds.

## Common pitfalls

> [!WARNING]
> - **Putting a writable directory first (`$HOME/work:$PATH`).** A file there with the same name as a real command shadows it, `sudo` included.
> - **Trusting `which`.** It only scans `PATH`. `type` also shows aliases, functions and built-in commands, which run before `PATH` is searched.
