# Overview: PLAYGROUND — ACLs On Whole Trees

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh acl-backup-playground`.
- The tree `/srv/data/ledger` (owner `ledger-owner`) with folders `2024`,
  `2025` and `tools`, a few data files and the script `tools/run-report.sh`.
- ACL entries for `auditor-ivy` and `temp-vendor` on every path, default
  entries for `auditor-ivy` on every folder, and one entry for `ledger-clerk`
  on `2025/q1.csv`.
- `/root/strip-acls.sh`, which runs `setfacl -R -b` on the tree.

## Things to try

- `getfacl -R -p /srv/data/ledger` and read every list.
- Compare `setfacl -R -m u:auditor-ivy:rx` with `rX` on a data file.
- Remove one name with `setfacl -R -x u:temp-vendor`.
- Save a backup, run the strip script, and restore with `setfacl --restore`.

## When you're done

```sh
astrona destroy acl-backup-playground
```
