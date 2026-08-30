# Overview: PLAYGROUND — Extending PATH Safely

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh astro-safe-path-playground`.
- User `candidate` (ordinary account; reach it with `su - candidate` from
  root, no password).
- `/home/candidate/work/helper-tool` — an executable script that is *not* the
  name of any system command.
- `candidate`'s dotfiles are the distro defaults; no decoy is planted.

## Things to try

- `su - candidate -c 'type helper-tool'` before any change — not found.
- Append `~/work` to `PATH` in `~candidate/.profile` (or `.bash_profile`), then
  in a fresh `su - candidate` run `helper-tool` by name.
- Compare `export PATH="$PATH:$HOME/work"` (append) with
  `export PATH="$HOME/work:$PATH"` (prepend) and a decoy:

  ```sh
  printf '#!/bin/bash\necho DECOY\n' > ~/work/ls && chmod +x ~/work/ls
  hash -r
  type ls
  ```

  Append: real `/bin/ls` still wins. Prepend: the decoy wins.
- Run `hash -r` and re-check `type ls` after each ordering change — see the
  command cache in action.

## When you're done

```sh
astrona destroy astro-safe-path-playground
```
