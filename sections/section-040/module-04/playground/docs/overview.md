# Overview: PLAYGROUND — Home Directories For Directory Users

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh mkhomedir-playground`.
- A TLS-secured OpenLDAP server for `dc=example,dc=com` with the group
  `developers` (GID `5000`) and the users `lfcsuser` (UID `10001`) and
  `newcomer` (UID `10002`), both with password `LfcsLdap!2024`.
- `sssd` configured and running, and `sss` in `nsswitch.conf`.
- No home folders for the directory users, and `pam_mkhomedir` switched off.

## Things to try

- `getent passwd newcomer`, then `ls -d /home/newcomer`.
- `sudo su - newcomer -c pwd` before and after switching on mkhomedir.
- Add a file to `/etc/skel` and see which homes get it.
- `sudo pam-auth-update --enable mkhomedir`, then `grep mkhomedir /etc/pam.d/common-session`.

## When you're done

```sh
astrona destroy mkhomedir-playground
```
