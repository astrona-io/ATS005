# Solution Walkthrough

This guide explains how to check user provisioning defaults, force user password resets, configure hard account-expiration dates, and safely lock or delete existing accounts.

---

## Step 1: Inspect user provisioning defaults

Before creating any new user accounts, it is essential to understand the system's default configurations. This helps ensure that newly created accounts automatically conform to organizational security standards.

```bash
useradd -D
```
*   `useradd -D`: The `-D` (defaults) option displays the default values used by the `useradd` command when no overrides are passed. This includes the default home directory base path (e.g. `/home`), default shell (e.g. `/bin/bash`), and default skeleton directory (`/etc/skel`).

You can also inspect system-wide account creation policies (such as default password lifespans or minimum UID boundaries) by viewing the `/etc/login.defs` configuration file:
```bash
cat /etc/login.defs | grep -E '^(UID_MIN|UID_MAX|PASS_MAX_DAYS|PASS_MIN_DAYS)'
```

---

## Step 2: Create contractor7 using system defaults

We need to create a new user named `contractor7` using the system's default configuration settings.

```bash
sudo useradd -m contractor7
```
*   `useradd -m`: The `-m` (make home) flag tells the system to create a home directory for the user. Since we do not specify any other overrides (like `-s` or `-d`), `useradd` automatically applies the defaults we inspected in Step 1. The home directory will be created under `/home/contractor7` and populate with configuration files copied from the `/etc/skel` skeleton directory.

---

## Step 3: Set and expire contractor7's password

To secure the new account, we will set a temporary password and force the user to change it on their very first login.

```bash
sudo passwd contractor7
sudo passwd -e contractor7
```
*   `passwd contractor7`: Prompts you to set a password for the user.
*   `passwd -e contractor7`: The `-e` (expire) flag instantly expires the user's password.
*   **Why we do this:** Setting a password first and then expiring it forces a password change upon their first authentication. Expiring an account that has no password can behave unpredictably depending on PAM configurations.
*   **Tip:** An alternative low-level command is `sudo chage -d 0 contractor7`, which sets the "last password change" date to `0` (the Unix Epoch), which the system interprets as an expired password.

---

## Step 4: Set the account to fully expire in 30 days

Unlike password aging (which only forces password updates), we want to set a hard expiration date for the entire user account itself. Once this date is reached, the account cannot log in under any circumstances.

```bash
sudo chage -E "$(date -d '+30 days' +%Y-%m-%d)" contractor7
```
*   `chage -E`: Sets the absolute account expiration date.
*   `$(date -d '+30 days' +%Y-%m-%d)`: Dynamically calculates the date exactly 30 days from now in the required `YYYY-MM-DD` format.

Verify the account aging configuration:
```bash
sudo chage -l contractor7
```
*   `-l` (list): Displays detailed account policy settings, showing the exact date when the account will expire.

---

## Step 5: Lock contractor3 without deleting files

We need to suspend `contractor3`'s access immediately while preserving their home directory, files, and settings intact for later audit or recovery.

```bash
sudo passwd -l contractor3
```
*   `passwd -l`: The `-l` (lock) flag locks the account's password by prefixing the encrypted password hash in `/etc/shadow` with a `!` character. This invalidates the password hash so password-based logins fail, but leaves the hash intact so it can be unlocked later with `passwd -u`.

Verify that the account is locked:
```bash
sudo passwd -S contractor3
```
*   `-S` (status): Reports the status of the account password. A locked account is indicated by an `L` (locked) status flag.

---

## Step 6: Delete the offboarded contractor1 account

Since `contractor1` has completed their contract and left the organization, we want to delete their account and wipe their home directory and mailbox files off the system entirely.

```bash
sudo userdel -r contractor1
```
*   `userdel -r`: The `-r` (remove) flag tells the system to delete the user's account entry from `/etc/passwd` AND recursively delete their home directory and mail spool.
*   **Warning:** Running `userdel` without `-r` will delete the user account but leave their home directory on disk. Those files will now belong to an unassigned UID, which poses a security and maintenance risk.

---

## Verification

Verify that all changes were successfully applied before completing the lab:

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
