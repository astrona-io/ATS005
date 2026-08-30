# Overview: PLAYGROUND — PAM Resource Limits & Concurrent Logins

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh astro-pam-limits-playground`.
- `jackie` — has `ulimit -Su 150` appended to `~/.bashrc` (the fragile "fix"),
  password `brown`.
- A persistent process owned by `jackie` (`systemd-run` unit `jackie-sleeper`),
  so `prlimit --pid` has a target.
- Group `operators` with members `ops-anna`, `ops-ben`, `ops-carl`.
- `pam_limits.so` already enabled in `/etc/pam.d/common-session`.

## Things to try

- `sudo -u jackie -i ulimit -Su` — jackie's live soft `nproc` limit.
  Compare with `prlimit --pid $(systemctl show -p MainPID --value jackie-sleeper) --nproc`.
- Write `/etc/security/limits.d/jackie-nproc.conf` with
  `jackie hard nproc 150`, then open a fresh session
  (`sudo -u jackie -i ulimit -Hu`) and see the hard cap take effect.
- Comment out the `pam_limits.so` line in `/etc/pam.d/common-session`, retest
  from a new session, and watch the limit stop applying. Put it back.
- Add `@operators hard maxlogins 1` in a drop-in and inspect it.
- `grep -rn . /etc/security/limits.d/` to see the drop-ins you have created.

## When you're done

```sh
astrona destroy astro-pam-limits-playground
```
