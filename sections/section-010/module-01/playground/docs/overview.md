# Overview: PLAYGROUND — User & Group Account Management

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh astro-user-group-mgmt-playground`.
- Groups `dev`, `op`, and `web` already created.
- User `user1`: default home `/home/user1`, its own private primary group,
  supplementary member of `web`. A file `~user1/ORIGINAL-HOME-MARKER.txt` marks
  the original home so you can tell whether a relocation moved the contents.
- `/root/dangerous.sh` — a root-owned script for practising a scoped `sudoers`
  rule.
- `/home/accounts` does **not** exist yet — on purpose.

## Things to try

- Move `user1`'s primary group to `dev` and its home to `/home/accounts/user1`,
  contents and all. Watch what fails if `/home/accounts` is missing, or if you
  forget `-m`.
- Provision a fresh `user2` in one `useradd` call with `dev` and `op` as
  supplementary groups.
- On `user1`, compare `usermod -G` against `usermod -aG` and check the group
  list afterwards with `id`.
- Write a `/etc/sudoers.d/` drop-in that lets `user2` run exactly
  `sudo bash /root/dangerous.sh` with no password — then confirm with
  `sudo -l -U user2` and `visudo -c`.

## When you're done

```sh
astrona destroy astro-user-group-mgmt-playground
```
