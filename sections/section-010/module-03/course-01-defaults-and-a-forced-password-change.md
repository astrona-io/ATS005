# Real Defaults And A Forced Password Change

Astronaut, every new crew member gets the standard boarding form unless you say otherwise. This part shows you how to read that form before you rely on it, and how to make a new crew member choose their own door code the first time they come aboard.

## Where "default" really comes from

Before you create an account with no options, do not assume its shell or home path. Ask the tool. Different ships fill in the boarding form differently.

### Read the real defaults, then create with them

`useradd -D` (for **D**isplay defaults), run with no user name, prints the current defaults and creates nothing. Read them, read the number rules, create `contractor7` with no overrides, and look at the result:

<!-- astrona:playground:renew -->

```sh
useradd -D
grep -E '^(UID_MIN|UID_MAX|PASS_MAX_DAYS|PASS_MIN_DAYS)' /etc/login.defs
sudo useradd -m contractor7
getent passwd contractor7
```

Expect something like:

```text
GROUP=100
HOME=/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/sh
...
UID_MIN                  1000
UID_MAX                  60000
PASS_MAX_DAYS   99999
PASS_MIN_DAYS   0
contractor7:x:1003:1003::/home/contractor7:/bin/sh
```

The `SHELL=` line from `useradd -D` is the shell that a plain `useradd -m` gave `contractor7`, as the account record confirms. On your machine it may be `/bin/sh` or `/bin/bash`. What matters is that you *checked* instead of guessing.

### Two files hold the defaults

The `useradd -D` values come from `/etc/default/useradd`, the standard boarding form. A separate set of number rules, such as UID ranges and password age limits, lives in `/etc/login.defs`. Organisations change both often, so check them on any machine you do not know instead of memorising "the Ubuntu defaults".

## Forcing a password change

An account that must "set its own password at first login" is a different, safer state than an account with *no* password. The account works the whole time; only its password dates demand a new door code first.

### Two commands, one effect

`passwd -e` (for **e**xpire) expires the current password at once, so a new one must be set at the next login:

```sh
sudo passwd -e contractor7
```

The lower-level command changes the "last changed" date in `/etc/shadow` directly. `chage` (short for *change age*) with `-d 0` sets the **d**ate of the last change to day 0, that is, 1 January 1970. It has exactly the same effect:

```sh
sudo chage -d 0 contractor7
```

### Set a real temporary password first

Both commands expect the account to *have* a password to expire. On a brand-new account that never had a password, PAM may skip the forced-change prompt for an empty field, depending on its configuration. So the predictable path is to set a real temporary password first, then expire it.

`chpasswd` (short for *change password*) sets a password with no prompt. It reads `user:password` pairs, one per line, from standard input and applies them all. `passwd` only ever prompts for one account at a time, so `chpasswd` is the one to use in scripts.

### Temporary password, then force the change

Set the temporary password, expire it, and read the dates back:

```sh
echo 'contractor7:Temp-123' | sudo chpasswd
sudo passwd -e contractor7
sudo chage -l contractor7
```

Expect something like:

```text
Last password change					: password must be changed
Password expires					: password must be changed
Account expires						: never
Maximum number of days between password change		: 99999
```

"Last password change: password must be changed" is the forced-change state. The account exists and works, but the next interactive login must set a new password before anything else.

## Common pitfalls

> [!WARNING]
> - **Assuming the default shell is `/bin/bash`.** On many systems `useradd -D` says `/bin/sh`. Check before a task says "use the defaults".
> - **Adding `-s` or `-d` when the task says "defaults".** Any override replaces the default. Use only `-m`.
> - **Expiring an account that has no password.** The forced-change prompt may not appear. Set a temporary password first, then expire it.
