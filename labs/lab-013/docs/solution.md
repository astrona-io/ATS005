# Solution Walkthrough

This walkthrough checks the account defaults, creates `contractor7` with a forced password change and an account expiry date, locks `contractor3`, and removes `contractor1`. Run every command on the lab machine (`astrona ssh ats-005-lab-013`).

---

## Step 1: Inspect user provisioning defaults

Before you create an account with the defaults, read what the defaults really are on this machine.

```bash
useradd -D
```
- `useradd -D`: the `-D` (defaults) option shows the values `useradd` uses when you pass no overrides. They include the home base path (for example `/home`), the default shell (for example `/bin/sh` or `/bin/bash`) and the welcome kit directory (`/etc/skel`).

The number rules for new accounts, such as password age limits and UID ranges, live in `/etc/login.defs`:
```bash
cat /etc/login.defs | grep -E '^(UID_MIN|UID_MAX|PASS_MAX_DAYS|PASS_MIN_DAYS)'
```

---

## Step 2: Create contractor7 using system defaults

Create `contractor7` with no overrides, so the defaults apply:

```bash
sudo useradd -m contractor7
```
- `useradd -m`: `-m` (make home) creates the home directory. Because you pass no other options (such as `-s` or `-d`), `useradd` uses the defaults you read in Step 1. The home directory is created under the default base, here `/home/contractor7`, and filled with files copied from `/etc/skel`.

---

## Step 3: Set and expire contractor7's password

Set a temporary password, then force the user to change it at their first login:

```bash
sudo passwd contractor7
sudo passwd -e contractor7
```
- `passwd contractor7` asks you to type a password for the user.
- `passwd -e contractor7`: `-e` (expire) expires the password at once. It sets the "last password change" field in `/etc/shadow` to `0`, which is what the grader checks.
- **Why both:** setting a password first and then expiring it forces a change at the first login. Expiring an account that has no password can behave differently depending on the PAM configuration.
- The lower-level command `sudo chage -d 0 contractor7` does the same: it sets the "last password change" date to `0` (1 January 1970), which the system reads as an expired password.

---

## Step 4: Set the account to fully expire in 30 days

Password aging only forces a new password. The task asks for a hard expiration date for the whole account: after that date, the account cannot log in at all.

```bash
sudo chage -E "$(date -d '+30 days' +%Y-%m-%d)" contractor7
```
- `chage -E` sets the account expiration date.
- `$(date -d '+30 days' +%Y-%m-%d)` works out the date 30 days from now in the `YYYY-MM-DD` format `chage` expects.

Check the dates:
```bash
sudo chage -l contractor7
```
- `-l` (list) shows all the password and account dates, including the day the account expires.

---

## Step 5: Lock contractor3 without deleting files

Stop `contractor3` from logging in at once, but keep the account, its home directory and its settings for the investigation:

```bash
sudo passwd -l contractor3
```
- `passwd -l`: `-l` (lock) puts a `!` in front of the password hash in `/etc/shadow`. The hash can no longer match, so password logins fail. The hash itself stays, so `passwd -u` can unlock the account later.

Check that the account is locked:
```bash
sudo passwd -S contractor3
```
- `-S` (status) reports the password state. `L` means locked.

---

## Step 6: Delete the offboarded contractor1 account

`contractor1` has left for good. Delete the account together with its home directory and mail spool:

```bash
sudo userdel -r contractor1
```
- `userdel -r`: `-r` (remove) deletes the account's entry from `/etc/passwd` **and** its home directory and mail spool.
- **Warning:** `userdel` without `-r` deletes the account but leaves the home directory on disk. Those files then belong to a UID with no name, which is a security and maintenance risk.

---

## Step 7: Check your work and submit

Check every change before you send the lab for grading:

```bash
# Verify contractor7 was created with defaults and skeleton files
id contractor7
getent passwd contractor7      # Confirm default home base (/home/contractor7) and default shell
ls -la /home/contractor7       # Confirm skeleton files (.bashrc, .profile, etc.) were copied

# Verify contractor7's password and expiration states
sudo chage -l contractor7
# Expect: "Password must be changed" (password is expired)
# Expect: "Account expires" shows the date 30 days from now

# Verify contractor3 lock state
sudo passwd -S contractor3
# Expect: "L" (locked)

# Verify contractor1 deletion
id contractor1
# Expect: "no such user"
ls -la /home/contractor1
# Expect: "No such file or directory" (confirming the home directory was deleted)
```

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-013
```
