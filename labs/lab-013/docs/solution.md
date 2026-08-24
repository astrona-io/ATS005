# Solution Walkthrough

## Step 1: Check useradd's defaults before creating anything

```bash
useradd -D
cat /etc/login.defs | grep -E '^(UID_MIN|UID_MAX|PASS_MAX_DAYS|PASS_MIN_DAYS)'
```

`useradd -D` alone prints the current defaults with no side effects.

## Step 2: Create contractor7 using those defaults

```bash
sudo useradd -m contractor7
```

No `-s`/`-d`/`-g` overrides — the account gets whatever shell and home base path Step 1 confirmed, and `/etc/skel` is copied in automatically via `-m`.

## Step 3: Give contractor7 a real password, then force a reset on next login

```bash
sudo passwd contractor7
sudo passwd -e contractor7
```

Set a real (temporary) password first — expiring a genuinely empty password field can behave unpredictably depending on PAM configuration. `-e` (expire) then forces a fresh password to be set at the very next login. The lower-level equivalent is `sudo chage -d 0 contractor7`.

## Step 4: Set the account to fully expire in 30 days

```bash
sudo chage -E "$(date -d '+30 days' +%Y-%m-%d)" contractor7
sudo chage -l contractor7
```

`-E` sets a hard account-expiration date, distinct from password aging (`-M`) — after that date the account cannot authenticate at all.

## Step 5: Lock contractor3 without deleting anything

```bash
sudo passwd -l contractor3
sudo passwd -S contractor3
```

`-l` prefixes the encrypted password field in `/etc/shadow`, preserving the original hash so it could be restored later with `passwd -u` — it does not delete or disable the account itself.

## Step 6: Remove the fully offboarded account

```bash
sudo userdel -r contractor1
```

`-r` removes the home directory and mail spool along with the account entries.

## Verification

```bash
id contractor7
# expect: valid uid/gid, using the default shell/home base confirmed in Step 1

sudo chage -l contractor7
# expect: "password must be changed" showing an already-past date,
# "account expires" showing the date 30 days from now

sudo passwd -S contractor3
# expect: L (locked)

id contractor1
# expect: "no such user"
ls /home/contractor1
# expect: "No such file or directory"
```

## Command Summary

```bash
useradd -D
cat /etc/login.defs | grep -E '^(UID_MIN|UID_MAX|PASS_MAX_DAYS|PASS_MIN_DAYS)'

sudo useradd -m contractor7
sudo passwd contractor7
sudo passwd -e contractor7
sudo chage -E "$(date -d '+30 days' +%Y-%m-%d)" contractor7
sudo chage -l contractor7

sudo passwd -l contractor3
sudo passwd -S contractor3

sudo userdel -r contractor1
id contractor1
```
