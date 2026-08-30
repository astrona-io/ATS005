# Overview: PLAYGROUND — Group Lifecycle Management

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh astro-group-lifecycle-playground`.
- Users `marta` (in `staff`, `projectx`) and `cilla` (in `staff`, `legacy-ops`).
- Group `legacy-ops` with GID `4200`, and `/srv/legacy-ops` full of files owned
  by GID `4200` — for showing that a rename keeps file ownership resolving.
- Group `temp-audit` (GID `4300`), unused, for a clean deletion.
- GID `5000` is free, for creating a group with a pinned GID.

## Things to try

- `groupadd -g 5000 datateam`, then add `marta` and `cilla` as supplementary
  members with `usermod -aG` (or `gpasswd -a`) and check `id` afterwards.
- Add `marta` to a group, then run `id marta` in your current shell and again
  in a fresh `su - marta` — see when the change shows up.
- `groupmod -n platform-ops legacy-ops`, then `ls -l /srv/legacy-ops` and
  `getent group platform-ops` — GID and members unchanged.
- `find / -xdev -gid 4300` before `groupdel temp-audit` to confirm nothing on
  disk still uses it.

## When you're done

```sh
astrona destroy astro-group-lifecycle-playground
```
