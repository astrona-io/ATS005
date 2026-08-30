# Overview: PLAYGROUND — POSIX Access Control Lists

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh astro-posix-acl-playground`.
- `/srv/projects/orion` — a shared tree owned by `team-lead:orion-team`, mode
  `750`, already containing `README.md` and `docs/spec.md`.
- `contractor-jane` and `auditor-tom` — real accounts, **not** members of
  `orion-team`.

## Things to try

- `getfacl /srv/projects/orion` on the untouched tree — see the standard bits
  echoed in ACL notation, no `mask` line yet.
- `setfacl -R -m u:contractor-jane:rwx /srv/projects/orion` and
  `setfacl -R -m u:auditor-tom:rx /srv/projects/orion`, then re-run `getfacl`
  and watch the `+` appear in `ls -ld`.
- Add default entries with `setfacl -d -m ...`, create a new file as one user,
  and `getfacl` it — the entries are already there.
- Set a narrow mask: `setfacl -m m::r-x /srv/projects/orion` and see `getfacl`
  annotate the capped entries with `#effective:`.
- `sudo -u contractor-jane touch /srv/projects/orion/t.txt` vs
  `sudo -u auditor-tom touch /srv/projects/orion/t2.txt` — one works, one is
  denied.

## When you're done

```sh
astrona destroy astro-posix-acl-playground
```
