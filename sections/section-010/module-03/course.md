# Account Lifecycle: Defaults, Aging & Locking

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS005/tree/main/sections/section-010/module-03/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-010/module-03/playground
> astrona destroy account-lifecycle-playground
> ```

Creating an account is the first moment of its lifecycle. The rest of the job is just as common: confirming what "default" actually means before assuming it, forcing a password reset without knowing the old password, telling a temporarily locked account apart from a permanently expired one, and removing an account cleanly with a deliberate choice about its home directory. None of this is the group-or-home-directory work from Module 1 — it is everything that happens *after* provisioning.

> *Locking an account (`passwd -l` / `usermod -L`) disables the password, not the account — an already-authorized SSH key still gets that user in unless you also disable the shell or remove the key.*

## Learning objectives

After this module you can:

- Read the effective `useradd` defaults with `useradd -D` and the numeric policy in `/etc/login.defs`, instead of assuming them.
- Force a password change at next login with `passwd -e` or `chage -d 0`, and explain why that is not the same as an empty password.
- Distinguish maximum password age (`chage -M`) from a hard account-expiration date (`chage -E`), and read both back with `chage -l`.
- Lock and unlock an account with `passwd -l` / `-u`, and confirm the state with `passwd -S`.
- Explain why a locked password does not block key-based SSH, and name two ways to close that gap.
- Remove an account with `userdel`, choosing `-r` or not based on what should happen to its home directory.

## Before you start

You should be able to provision an account (Module 1), use `sudo`, and know roughly that `/etc/passwd` holds account records and `/etc/shadow` holds the password hash and its aging fields.

The playground VM already has:

- `contractor3` — a real password **and** an authorized SSH key. The matching private key is at `/root/contractor3_key`, so you can SSH to `contractor3@localhost` from inside the VM.
- `contractor1` — a home directory with `NOTES.txt`, plus a file **outside** home at `/var/backups/contractor1/dump.sql`.
- `contractor7` — not created yet; you create it.
- `sshd` running.

Open a shell on it with:

```sh
astrona ssh astro-account-lifecycle-playground
```

Every command block below runs **inside that VM**.

## Where this fits

The aging fields this module sets live in `/etc/shadow`, but they are *enforced* by PAM at authentication time — the mechanism Section 020 covers. Two distinctions here are the ones incident response hinges on: a locked *password* is not a locked *account* (key auth ignores the password field), and a bounded *password* lifetime (`-M`) is not a bounded *account* lifetime (`-E`). Getting the layer right is the difference between "they can't log in" and "they still can".

## Where "default" actually comes from

Before creating an account with no explicit overrides, do not assume the shell or home base path. Ask the tool. `useradd -D` (**D**isplay defaults), run with no username, prints the current defaults and creates nothing:

```sh
useradd -D
```

These values come from `/etc/default/useradd`. A separate set of numeric policy fields — UID ranges, password-aging bounds — lives in `/etc/login.defs`. Organisations customise both routinely, so "the standard Ubuntu defaults" is worth verifying on an unfamiliar system rather than memorising.

> [!TIP]
> **Try it — read the real defaults, then create with them**
>
> ```sh
> useradd -D
> grep -E '^(UID_MIN|UID_MAX|PASS_MAX_DAYS|PASS_MIN_DAYS)' /etc/login.defs
> sudo useradd -m contractor7
> getent passwd contractor7
> ```
>
> Expect something like:
>
> ```text
> GROUP=100
> HOME=/home
> INACTIVE=-1
> EXPIRE=
> SHELL=/bin/sh
> ...
> UID_MIN                  1000
> UID_MAX                  60000
> PASS_MAX_DAYS   99999
> PASS_MIN_DAYS   0
> contractor7:x:1003:1003::/home/contractor7:/bin/sh
> ```
>
> The `SHELL=` line from `useradd -D` is what a plain `useradd -m` used for `contractor7` — confirmed in the passwd record. On your VM it may be `/bin/sh` or `/bin/bash`; the point is you *checked* rather than guessed.

## Forcing a password reset — not the same as no password

An account required to "set its own password on first login" is a different, safer state than an account with *no* password. `passwd -e` (**e**xpire) immediately expires the current password so a new one must be set at the next login — a fully functional account throughout, just with an aging field demanding a fresh credential first:

```sh
sudo passwd -e contractor7
```

The lower-level equivalent works directly on `/etc/shadow`'s "last changed" field. `chage` (read: *change age*) with `-d 0` (**d**ate of last change = day 0, i.e. 1970) has the identical forcing effect:

```sh
sudo chage -d 0 contractor7
```

Either form assumes the account *has* a password to expire. On a brand-new account with no password ever set, PAM's handling of a genuinely empty field can skip the forced-change prompt entirely, depending on configuration — which is why the predictable path is to set a real temporary password first, then expire it.

To set that temporary password without an interactive prompt, use `chpasswd` (read: *change password*): it reads `user:password` pairs, one per line, from standard input and applies them in a batch. `echo 'contractor7:Temp-123' | sudo chpasswd` sets one. It is the scriptable counterpart to `passwd`, which only ever prompts for one account at a time.

> [!TIP]
> **Try it — temporary password, then force the change**
>
> ```sh
> echo 'contractor7:Temp-123' | sudo chpasswd
> sudo passwd -e contractor7
> sudo chage -l contractor7
> ```
>
> Expect something like:
>
> ```text
> Last password change					: password must be changed
> Password expires					: password must be changed
> Account expires						: never
> Maximum number of days between password change		: 99999
> ```
>
> "Last password change: password must be changed" is the forced-reset state — the account exists and works, but the next interactive login has to set a new password before anything else.

## Password aging vs. account expiration — two different fields

These get conflated, and a task that says "password" versus "account" is testing whether you know they are separate:

- `chage -M <days>` sets the **maximum password age** — how long the *current password* stays valid before the user must change it. The account keeps existing indefinitely; only the password's lifecycle is bounded.
- `chage -E <date>` sets a hard **account expiration date**. After it, the account cannot authenticate *at all*, regardless of password validity.

```sh
sudo chage -M 30 contractor7
sudo chage -E "$(date -d '+30 days' +%F)" contractor7
```

Enforcement of `-E` happens at authentication time, not retroactively — setting the date does not kill an already-open session. Killing active sessions, if a task implies it, is a separate action.

> [!TIP]
> **Try it — set both, read both back**
>
> ```sh
> sudo chage -M 30 contractor7
> sudo chage -E "$(date -d '+30 days' +%F)" contractor7
> sudo chage -l contractor7
> ```
>
> Expect something like:
>
> ```text
> Last password change					: password must be changed
> Password expires					: password must be changed
> Password inactive					: never
> Account expires						: Sep 29, 2026
> Minimum number of days between password change		: 0
> Maximum number of days between password change		: 30
> ```
>
> `-M` changed "Maximum number of days between password change" to `30`; `-E` set "Account expires" to a real date. They are different lines because they are different mechanisms. `-l` (**l**ist) is how you confirm a `chage` change landed instead of trusting the silent success.

## Locking and unlocking without deleting

An account "under investigation" must stop authenticating immediately without losing its configuration or data:

```sh
sudo passwd -l contractor3
sudo passwd -S contractor3
```

`passwd -l` (**l**ock) prefixes the encrypted password field in `/etc/shadow` (typically with `!`) so the stored hash can never match any input. It does not clear the original hash — unlocking with `passwd -u` (**u**nlock) restores the *exact previous password*, not a blank one. `usermod -L` / `-U` are the documented equivalents on the `usermod` side. `passwd -S` (**S**tatus) reports a one-letter code — `L` locked, `P` usable password, `NP` no password — the fastest way to check state without reading `/etc/shadow`.

> [!TIP]
> **Try it — lock, and read the status letter**
>
> ```sh
> sudo passwd -l contractor3
> sudo passwd -S contractor3
> ```
>
> Expect something like:
>
> ```text
> passwd: password expiry information changed.
> contractor3 L 08/30/2026 0 99999 7 -1
> ```
>
> The `L` in the second field is the locked state. The password hash is still there underneath the `!` prefix — `passwd -u contractor3` would bring the old password straight back.

### The SSH key blind spot

This is the most important caveat in the module: **locking the password field does nothing to key-based SSH.** If a locked account already has a key in `~/.ssh/authorized_keys` and `sshd` permits key auth, that user still logs in — `passwd -l` never touches that file, and key auth does not consult the password field. Closing a *complete* lockout means also removing or renaming `authorized_keys`, or disabling the shell:

```sh
sudo usermod -s /usr/sbin/nologin contractor3
```

`/usr/sbin/nologin` is a real program that prints a refusal and exits non-zero, so it ends the session immediately after authentication.

> [!TIP]
> **Try it — the locked account still lets a key in, until the shell is gone**
>
> ```sh
> sudo passwd -S contractor3
> ssh -i /root/contractor3_key -o StrictHostKeyChecking=no contractor3@localhost id
> sudo usermod -s /usr/sbin/nologin contractor3
> ssh -i /root/contractor3_key -o StrictHostKeyChecking=no contractor3@localhost id
> ```
>
> Expect something like:
>
> ```text
> contractor3 L ...
> uid=1001(contractor3) gid=1001(contractor3) groups=1001(contractor3)
> This account is currently not available.
> ```
>
> The password shows `L`, yet the first `ssh` runs `id` as `contractor3` — key auth bypassed the lock entirely. Only after the shell is set to `nologin` does the second attempt get refused.

> [!WARNING]
> **Common pitfalls — locking**
>
> - "`passwd -l` locked the account" — it locked the *password*. Key-based SSH, and anything else that does not check the password field, still works. Address the key or the shell for a full lockout.
> - Deleting the hash to lock — do not. `passwd -l` deliberately keeps it so `passwd -u` can restore the original password. Blanking `/etc/shadow` by hand loses it.
> - `chage -E` set, but the user is still logged in — expiry is checked at authentication, not retroactively. Terminate the session separately if that is required.

## Removing an account cleanly

```sh
sudo userdel -r contractor1
```

`userdel` (read: *user delete*) with `-r` (**r**emove) deletes the account's entries **and** its home directory and mail spool. Its scope stops there — it does **not** search the rest of the filesystem for other files the user owns elsewhere. Plain `userdel contractor1` removes the account entries from `/etc/passwd`, `/etc/shadow`, and group membership but leaves the home directory behind as an orphan. Which is correct depends entirely on whether the task means "gone completely" or "preserve data for handoff".

> [!TIP]
> **Try it — see exactly what `-r` does and does not touch**
>
> ```sh
> ls -la /home/contractor1
> ls -l /var/backups/contractor1
> sudo userdel -r contractor1
> ls /home/ | grep contractor1 || echo "home gone"
> ls -l /var/backups/contractor1
> ```
>
> Expect something like:
>
> ```text
> ... NOTES.txt
> -rw-r--r-- 1 contractor1 contractor1 32 Aug 30 12:00 dump.sql
> ...
> home gone
> -rw-r--r-- 1 1002 1002 32 Aug 30 12:00 dump.sql
> ```
>
> The home directory and `NOTES.txt` are removed. `/var/backups/contractor1/dump.sql` is untouched — `-r` never looked there — and now shows a bare numeric owner because the name `contractor1` no longer resolves.
