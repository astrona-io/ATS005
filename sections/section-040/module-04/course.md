# Home Directories For Directory Users

Astronaut, a crew member from the fleet registry can be known to the ship and still arrive to an empty doorway: no cabin, no locker, nowhere to put a bag. This module gives every registry user a home on first login, stocked from a standard starter kit.

## Learning objectives

After this module you can:

- Explain why a user from the directory has no home folder until something creates it.
- Explain what `/etc/skel` is and add a file to it.
- Switch on `pam_mkhomedir` with `pam-auth-update --enable mkhomedir`, and say where it sits in the login steps.
- Prove the result with a first login as a user who never logged in before.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **Users from the directory.** `sssd` and `nsswitch.conf` make registry users visible to `getent` and `id`.
- **Home folders.** `useradd -m` copies `/etc/skel` into a new home for a local user.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- A TLS-secured LDAP server on `127.0.0.1` serving `dc=example,dc=com`, with a `developers` group (GID `5000`) and two users: `lfcsuser` (UID `10001`) and `newcomer` (UID `10002`). Both have home `/home/<name>` set in the directory.
- `sssd` configured and running, with `sss` in `nsswitch.conf`, so both users resolve.
- No home folders for them, and `pam_mkhomedir` **not** switched on.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh mkhomedir-playground
```

Every command block in the parts runs **inside that virtual machine**.

## How this module is laid out

1. [The Missing Home](./course-01-the-missing-home.md): what a login does when the home folder is not there, and what `/etc/skel` holds.
2. [Creating Homes On First Login](./course-02-creating-homes-on-first-login.md): `pam-auth-update --enable mkhomedir`, a starter file in `/etc/skel`, and a first-login test.
   - Mission: [Home Directories For Directory Users Lab](../../../labs/lab-044/docs/question.md)
3. [Wrap-Up: Mission Debrief](./course-03-wrap-up.md)

## Why this matters

The directory stores a home path, not a home folder. Without `pam_mkhomedir`, every new registry user lands in `/` on the first login. The exam asks for the switch, and a real fleet needs it before the first crew member arrives.

> *A cabin number in the registry is not a cabin.*
