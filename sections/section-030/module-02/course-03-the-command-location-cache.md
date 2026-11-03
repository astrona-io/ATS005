# The Command-Location Cache

Astronaut, once the ship has found a crew member by name, it remembers where they were, so it does not search every deck again. This part shows you how that memory can hide a `PATH` change, and the one command that clears it.

## Bash remembers where commands are

Bash keeps the locations of commands it has already found in a table, so it does not scan `PATH` on every run. That table can hide a `PATH` change: if `ls` was found earlier in a shell, `type ls` may keep showing the old location after `PATH` changed.

### Watch the cache hide a change until you clear it

Open a shell as `candidate`, put `~/work` first, run `ls` once so bash remembers it, plant a decoy, and look before and after `hash -r`:

<!-- astrona:playground:renew -->

```sh
su - candidate
export PATH="$HOME/work:$PATH"
ls >/dev/null
printf '#!/bin/bash\necho "decoy"\n' > ~/work/ls && chmod +x ~/work/ls
type ls
hash -r
type ls
exit
```

Expect something like:

```text
ls is hashed (/usr/bin/ls)
ls is /home/candidate/work/ls
```

The first `type ls` still shows the remembered `/usr/bin/ls`, even though `~/work/ls` now sits earlier in `PATH`. After `hash -r`, the lookup is done again and `type` reports the decoy.

If your shell has an alias for `ls`, `type ls` reports the alias instead of either line. `type -P ls` shows only the file that the `PATH` search finds.

### What `hash` does

`hash` is the built-in command that manages this table. `hash -r` (**r**eset) clears it and forces a fresh lookup for every name.

> [!TIP]
> After any `PATH` change, run `hash -r` before you trust a `type` or `which` result. Otherwise bash may answer from memory.

## Common pitfalls

> [!WARNING]
> - **Trusting `type` or `which` right after a `PATH` change.** Bash may answer from its cache. Run `hash -r` first.
> - **Expecting `hash -r` to change `PATH`.** It only clears remembered locations. The search order is still whatever `PATH` says.
> - **Leaving a decoy behind.** Remove `~/work/ls` when you are done, so it cannot confuse later checks.

## Your mission: Safe PATH Extension & Precedence Lab

You can now append a personal directory to `PATH`, save it in the login-shell file the account reads, and prove with a fresh lookup that a decoy never wins. Now prove it in a graded mission: a fresh ship where `candidate` wants `~/work` on `PATH` for good, and a decoy `ls` must never beat the real one.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop safe-path-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-032
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-032
```

Read the task in [`question.md`](../../../labs/lab-032/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-032
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-032
astrona start safe-path-playground
```
