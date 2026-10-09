# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module was about the rest of an account's life: its defaults, its door code, its expiry date, a lock, and its removal.

**From [Real Defaults And A Forced Password Change](./course-01-defaults-and-a-forced-password-change.md):**

- `useradd -D` shows the real defaults from `/etc/default/useradd`. `/etc/login.defs` holds the number rules.
- `chpasswd` sets a password from `user:password` lines with no prompt.
- `passwd -e <user>` or `chage -d 0 <user>` forces a new password at the next login. Set a temporary password first.

**From [Password Aging And Account Expiration](./course-02-password-aging-and-account-expiration.md):**

- `chage -M <days>` limits the password's life. `chage -E <date>` ends the account's life.
- `chage -l <user>` shows both. Expiry is checked at login, not afterwards.

**From [Locking An Account And The SSH Key Gap](./course-03-locking-and-the-ssh-key-gap.md):**

- `passwd -l` puts `!` in front of the hash; `passwd -u` restores the old password; `passwd -S` shows `L`, `P` or `NP`.
- A locked password does not stop SSH key login. Remove the key or set the shell to `/usr/sbin/nologin`.

**From [Removing An Account Cleanly](./course-04-removing-an-account.md):**

- `userdel -r` removes the account, its home directory and its mail spool. Plain `userdel` leaves the home.
- Files outside the home stay, with a bare UID as owner.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Account Defaults, Password Aging & Locking Lab](../../../labs/lab-013/docs/question.md) | Removing An Account Cleanly | created `contractor7` with the real defaults, a forced password change and a 30-day expiry, locked `contractor3`, and removed `contractor1` with its home |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. How do you see which shell a plain <code>useradd -m</code> will give a new user?</summary>

Run `useradd -D` and read the `SHELL=` line. It comes from `/etc/default/useradd`.
</details>

<details>
<summary>2. What is the difference between <code>chage -d 0</code> and an empty password?</summary>

`chage -d 0` keeps the password but forces the user to choose a new one at the next login. An empty password is a different state, and PAM may not show the forced-change prompt for it.
</details>

<details>
<summary>3. A task says the account must stop working in 14 days. Do you use <code>chage -M 14</code> or <code>chage -E</code>?</summary>

`chage -E` with the date 14 days from now. `-M` only limits how long the password stays valid; the account keeps working with a new password.
</details>

<details>
<summary>4. You ran <code>passwd -l contractor3</code>. What does <code>passwd -u contractor3</code> give back?</summary>

The exact old password. The lock only put `!` in front of the hash and kept the hash.
</details>

<details>
<summary>5. <code>passwd -S</code> shows <code>L</code>, but the user still logs in with SSH. How?</summary>

With an SSH key. Key login does not check the password field. Remove the key from `authorized_keys` or set the shell to `/usr/sbin/nologin`.
</details>

<details>
<summary>6. After <code>userdel -r contractor1</code>, a file of theirs in <code>/var/backups</code> shows a number as its owner. Why?</summary>

`-r` only removes the home directory and mail spool. The other file stayed, and its owner's name no longer exists, so `ls -l` shows the UID.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy account-lifecycle-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-013
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-010/module-03/playground`. It always starts clean, so nothing you broke carries over.

> *Check the defaults, expire the password or the account on purpose, lock in layers, and remove with `-r` only when the quarters should go too.*
