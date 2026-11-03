# Account Lifecycle: Defaults, Aging & Locking

Astronaut, creating an account is only the first moment of its life. The rest of the job is just as common. You confirm what "default" really means before you rely on it, force a new door code (password) without knowing the old one, tell a temporarily locked account apart from an expired one, and remove an account cleanly with a deliberate choice about its quarters. This module covers everything that happens to a crew member's entry *after* they come aboard.

## Learning objectives

After this module you can:

- Read the real `useradd` defaults with `useradd -D` and the number rules in `/etc/login.defs`, instead of assuming them.
- Force a password change at the next login with `passwd -e` or `chage -d 0`, and explain why that is not the same as an empty password.
- Tell the maximum password age (`chage -M`) from a hard account expiration date (`chage -E`), and read both back with `chage -l`.
- Lock and unlock an account with `passwd -l` and `passwd -u`, and confirm the state with `passwd -S`.
- Explain why a locked password does not block key-based SSH, and name two ways to close that gap.
- Remove an account with `userdel`, choosing `-r` or not by what should happen to its home directory.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **How to create an account with `useradd`** and run commands with `sudo`.
- **The two account files.** `/etc/passwd` is the crew roster: one line per account. `/etc/shadow` is the locked safe that holds each password hash and its dates.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- `contractor3`, with a real password **and** an authorized SSH key. The matching private key is at `/root/contractor3_key`, so you can connect to `contractor3@localhost` with SSH from inside the machine.
- `contractor1`, with a home directory holding `NOTES.txt`, plus a file **outside** the home at `/var/backups/contractor1/dump.sql`.
- No `contractor7` yet. You create it.
- `sshd` (the SSH server) running.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh account-lifecycle-playground
```

Every command block in the parts runs **inside that virtual machine**.

## How this module is laid out

1. [Real Defaults And A Forced Password Change](./course-01-defaults-and-a-forced-password-change.md): `useradd -D`, `/etc/login.defs`, a temporary password with `chpasswd`, and `passwd -e` or `chage -d 0`.
2. [Password Aging And Account Expiration](./course-02-password-aging-and-account-expiration.md): `chage -M` against `chage -E`, read back with `chage -l`.
3. [Locking An Account And The SSH Key Gap](./course-03-locking-and-the-ssh-key-gap.md): `passwd -l`, `-u` and `-S`, and why a key still gets in until the shell is `nologin`.
4. [Removing An Account Cleanly](./course-04-removing-an-account.md): `userdel` with and without `-r`.
   - Mission: [Account Defaults, Password Aging & Locking Lab](../../../labs/lab-013/docs/question.md)
5. [Wrap-Up: Mission Debrief](./course-05-wrap-up.md)

## Why this matters

The dates this module sets live in `/etc/shadow`, but PAM (Pluggable Authentication Modules, the airlock checklist every crew member passes when coming aboard) enforces them when someone logs in. Two differences decide whether an incident is really contained. A locked *password* is not a locked *account*, because key login ignores the password field. And a limited *password* lifetime (`-M`) is not a limited *account* lifetime (`-E`). Getting the layer right is the difference between "they cannot log in" and "they still can".

> *Locking an account (`passwd -l` or `usermod -L`) disables the password, not the account: an SSH key that is already authorized still lets that user in unless you also disable the shell or remove the key.*
