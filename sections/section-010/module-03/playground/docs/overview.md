# Overview: PLAYGROUND — Account Lifecycle: Defaults, Aging & Locking

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh astro-account-lifecycle-playground`.
- `contractor3` — has a real password *and* an authorized SSH key
  (`/home/contractor3/.ssh/authorized_keys`). The matching private key is at
  `/root/contractor3_key`, so you can `ssh contractor3@localhost` from inside
  the VM.
- `contractor1` — home directory with `NOTES.txt`, plus a file **outside** home
  at `/var/backups/contractor1/dump.sql`.
- `contractor7` — not created; you create it with `useradd`.
- `sshd` running, for the loopback login demo.

## Things to try

- `useradd -D` and `grep -E '^(UID_MIN|PASS_MAX_DAYS)' /etc/login.defs` — see
  the defaults before creating `contractor7` with a plain `useradd -m`.
- Give `contractor7` a temporary password, then `passwd -e contractor7` (or
  `chage -d 0 contractor7`), and `chage -l contractor7` to read the aging state.
- `chage -M 30` vs `chage -E "$(date -d '+30 days' +%F)"` — compare what each
  line of `chage -l` output changes.
- `passwd -l contractor3`, then `passwd -S contractor3`, then
  `ssh -i /root/contractor3_key -o StrictHostKeyChecking=no contractor3@localhost id`
  — the password is locked, the key still works. Then
  `usermod -s /usr/sbin/nologin contractor3` and try again.
- `userdel -r contractor1`, then look for what is left at
  `/var/backups/contractor1/`.

## When you're done

```sh
astrona destroy astro-account-lifecycle-playground
```
