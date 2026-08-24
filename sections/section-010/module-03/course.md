# Chapter 3: Account Lifecycle — Defaults, Aging & Locking

> *Locking an account (`passwd -l` / `usermod -L`) disables the password, not the account — an already-authorized SSH key still gets that user in unless you separately disable the shell or the key.*

Creating an account is only the first moment of its lifecycle. The rest of the job is just as likely to show up on the exam: confirming exactly what "default" means before assuming it, forcing a password reset without ever knowing what the old password was, distinguishing an account that's temporarily locked from one that's permanently expired, and removing an account cleanly with a deliberate choice about what happens to its home directory. None of this is `useradd`/`usermod` in the group-or-home-directory sense from Chapter 1 — it's everything that happens *after* provisioning.

---

## Part I: Where "Default" Actually Comes From

Before creating an account with no explicit overrides, don't assume you know what shell or home directory base path it will get. Ask the tool directly:

```bash
useradd -D
```

Run with no username, this prints the *current* defaults — default shell, default home base directory, password aging defaults — without creating anything or having any side effect. These values come from `/etc/default/useradd`, plus a set of numeric policy fields (UID ranges, password aging bounds) that live separately in `/etc/login.defs`:

```bash
cat /etc/login.defs | grep -E '^(UID_MIN|UID_MAX|PASS_MAX_DAYS|PASS_MIN_DAYS)'
```

Check `man useradd`'s closing section and `man 5 login.defs` directly — organizations customize both files routinely, so "the standard Ubuntu defaults" is an assumption worth verifying on any unfamiliar system, not a fact worth memorizing once.

Creating the account itself, with no shell/home/group overrides, then simply becomes:

```bash
sudo useradd -m contractor7
```

`-m` creates the home directory and seeds it from `/etc/skel` — take a look inside `/etc/skel` sometime; anything placed there (a `.bashrc`, a welcome file) is copied automatically into every new account's home directory going forward.

---

## Part II: Forcing a Password Reset — Not the Same as No Password

A contractor account with a policy requirement to "set their own password on first login" is a different, more secure state than an account with *no* password at all. The distinction matters:

```bash
sudo passwd -e contractor7
```

Check `man 1 passwd`'s `-e` (expire) flag. It immediately expires the account's *current* password state, forcing a new password to be set at the very next login — there is a real, fully functional account throughout, just with an aging field that demands a fresh credential before anything else can happen. The lower-level equivalent, working directly against `/etc/shadow`'s aging fields:

```bash
sudo chage -d 0 contractor7
```

Setting the "last changed" date to `0` has the identical forcing effect — check `man 1 chage`'s `-d` flag. Either form assumes the account *has* a real password to expire in the first place. If it doesn't (a brand-new account with no password ever set), PAM's behavior around a genuinely empty password field can bypass the expected forced-change prompt entirely, depending on configuration — which is exactly why setting a real temporary password first, then expiring it, is the predictable, deliberate path rather than leaving the field blank and hoping.

---

## Part III: Password Aging vs. Account Expiration — Two Different Fields

These two are commonly conflated, and a task that says "password" versus "account" is testing whether you know they are genuinely separate mechanisms:

- `chage -M <days>` sets the **maximum password age** — how long the *current password* remains valid before the user must change it. The account itself keeps existing indefinitely; only the password's own lifecycle is bounded.
- `chage -E <date>` sets a hard **account expiration date**. After that date, the account cannot be used to authenticate *at all*, regardless of the password's own validity.

```bash
sudo chage -E "$(date -d '+30 days' +%Y-%m-%d)" contractor7
sudo chage -l contractor7
```

Check `man 1 chage`'s `-E` flag for the account-expiration semantics, and use `-l` (list) afterward to read back the full current aging state — confirm both the forced password-change field and the account-expiration field show exactly what you just set, rather than trusting the command silently succeeded.

Enforcement of `-E` happens at authentication time, not retroactively: setting an expiry date doesn't terminate an already-open session the moment the date is set. If a task also implies killing active sessions, that's a separate action entirely, not something `chage` performs on its own.

---

## Part IV: Locking and Unlocking Without Deleting

An account "under investigation" needs to stop authenticating immediately, without losing any of its configuration or data:

```bash
sudo passwd -l contractor3
sudo passwd -S contractor3
```

Check `man 1 passwd`'s `-l` flag. It works by **prefixing** the encrypted password field in `/etc/shadow` (typically with `!` or `!!`) so the stored hash can never match any input — critically, it does not clear or destroy the original hash, so unlocking later restores the *exact previous password*, not a blank field. `usermod -L`/`-U` are documented equivalents on the `usermod` side of the same mechanism.

`passwd -S` reports a one-letter status code — `L` for locked — which is the fastest way to confirm state without reading `/etc/shadow` by hand.

### The SSH Key Blind Spot

This is the single most important caveat in this chapter: **locking the password field does nothing to key-based SSH authentication.** If `contractor3` (or any locked account) already has an authorized key in `~/.ssh/authorized_keys`, and the SSH daemon's configuration permits key-based auth, that user can still log in — `passwd -l` never touches that file, and key auth typically doesn't consult the password field at all. A task that implies a *complete* lockout, not just a password-layer block, requires separately addressing the SSH key (removing/renaming `authorized_keys`) or disabling the shell entirely:

```bash
sudo usermod -s /usr/sbin/nologin contractor3
```

Know which layer a task is actually asking you to lock.

---

## Part V: Removing an Account Cleanly

```bash
sudo userdel -r contractor1
```

Check `man 8 userdel`'s `-r` flag. Its scope is precise: it removes the home directory and the user's mail spool. It does **not** search the rest of the filesystem for other files this user might own elsewhere — those are untouched either way, `-r` or not. Plain `userdel contractor1` (no `-r`) removes the account entries from `/etc/passwd`/`/etc/shadow`/group membership but leaves the home directory sitting there as an orphan. Whether that's correct behavior depends entirely on whether the task implies "gone completely" or "preserve data for handoff" — read the requirement carefully before picking one.

## Self-Check

1. Before running `useradd` with no overrides, how do you find out what shell and home base path it will actually use?
2. What's the practical difference between `chage -M 30` and `chage -E` set to 30 days from now?
3. `passwd -l` was just run against an account. Under what circumstance could that user still log in anyway?
4. What's left behind after `userdel contractor1` (no `-r` flag) that would be removed by `userdel -r contractor1`?
