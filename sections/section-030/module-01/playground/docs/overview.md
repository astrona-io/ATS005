# Overview: PLAYGROUND — System-Wide & Personal Environment Profiles

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh astro-env-profiles-playground`.
- Users `candidate` and `otheruser` (ordinary accounts, no password needed —
  reach them with `su - candidate` from root).
- `/etc/cron.d/env-probe` — a cron job that writes `env` to
  `/home/candidate/cron-env.txt` every minute.
- `env-probe.service` — a systemd unit that writes `env` to `/run/env-probe.txt`
  when started (`systemctl start env-probe.service`).
- `/etc/environment`, `/etc/profile.d/`, and all dotfiles are untouched.

## Things to try

- Add `COMPANY_PROXY=http://proxy.internal:3128` to `/etc/environment`, then
  check `su - candidate -c 'echo $COMPANY_PROXY'` and
  `su candidate -c 'echo $COMPANY_PROXY'` (login vs non-login).
- Drop an `export FOO=...` into `/etc/profile.d/company.sh` and compare the same
  two `su` forms — one sees it, one does not.
- Put a different `export MARKER=...` line in `~candidate/.bash_profile` and in
  `~candidate/.bashrc`, then see which fires for `su - candidate` vs plain
  `bash`.
- `cat /home/candidate/cron-env.txt` and `cat /run/env-probe.txt` after setting
  a variable — see what cron and systemd actually inherit.

## When you're done

```sh
astrona destroy astro-env-profiles-playground
```
