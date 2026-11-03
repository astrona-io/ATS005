# Overview: PLAYGROUND — Resource Limits With systemd

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh systemd-limits-playground`.
- `ledger-sync.service`: a running service (`sleep infinity`) that has no
  limits set in a drop-in.
- The user `dana` with UID `2010`.

## Things to try

- `systemctl show ledger-sync -p LimitNOFILE` and read
  `/proc/<pid>/limits` for the same process.
- Add `/etc/systemd/system/ledger-sync.service.d/limits.conf` with
  `LimitNOFILE=4096`, run `daemon-reload` and `restart`, and read the process
  limits again.
- Put a `nofile` line in `/etc/security/limits.d/` and check that the running
  service does not change.
- `systemctl show user-2010.slice -p TasksMax -p MemoryMax`, then add a
  drop-in under `/etc/systemd/system/user-2010.slice.d/`.
- Try `sudo systemctl set-property user-2010.slice TasksMax=50` and look for
  the drop-in it writes under `/etc/systemd/system.control/`.

## When you're done

```sh
astrona destroy systemd-limits-playground
```
