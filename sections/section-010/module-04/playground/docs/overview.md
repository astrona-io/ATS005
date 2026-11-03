# Overview: PLAYGROUND — Sudoers Drop-ins, Aliases & Group Rules

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh sudoers-playground`.
- Users `anna` and `ben` (both in the group `webops`) and `cleo` (not in it).
- `/etc/sudoers.d/old-ops.bak`: a generous rule for `cleo` that `sudo` skips
  because the file name contains a dot.
- The `ssh` service, running, to point rules at.

## Things to try

- `sudo grep -n includedir /etc/sudoers` and `sudo ls /etc/sudoers.d`.
- `sudo -l -U cleo`, then rename the backup file to `old-ops` and ask again.
  Put it back afterwards.
- Check a broken file with `sudo visudo -c -f /tmp/bad-rule` and read the
  exit code.
- Write `/etc/sudoers.d/webops` with a `Cmnd_Alias` and a `%webops` rule, then
  compare `sudo -l -U anna` and `sudo -l -U cleo`.
- Try an allowed and a refused command with `sudo -u anna sudo -n <command>`.

## When you're done

```sh
astrona destroy sudoers-playground
```
