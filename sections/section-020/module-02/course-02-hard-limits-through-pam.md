# Hard Limits Through PAM

Astronaut, the right place for an allowance is the airlock checklist, not a note in one crew member's quarters. This part shows you the four-column format of `/etc/security/limits.d/`, the PAM module that reads it, and how to retire the old `~/.bashrc` line.

## The four-column format

The proper fix lives in `/etc/security/limits.conf`, or better in a separate drop-in file under `/etc/security/limits.d/`. These are the allowance tables. Every line has four columns.

### A hard limit for `jackie`

Using the live number you read for `jackie`, the line is:

```text
jackie  hard  nproc  150
```

That one line says: for the user `jackie`, set a hard ceiling of 150 processes.

### What each column means

The general form is:

```text
<domain>  <type>  <item>  <value>
```

- **domain**: who the rule applies to. A bare username (`jackie`), a group with `@` (`@operators`), or `*` for everyone.
- **type**: `soft` or `hard`. `hard` is the ceiling a normal user cannot raise.
- **item**: the resource. `nproc` (maximum processes), `maxlogins` (concurrent sessions), `fsize`, `nofile` and more, each something `pam_limits.so` knows how to enforce.
- **value**: the number.

A drop-in under `limits.d/` is easier to find, review and remove later than a hand edit of the big `limits.conf` file. It is the same idea as drop-in files in `/etc/sudoers.d/`.

## The module that reads the file

None of these lines does anything unless `pam_limits.so` is part of the login path in use. `pam_limits.so` is the step on the airlock checklist that reads `limits.conf` and `limits.d` and applies them when a session opens. `limits.conf` is data; `pam_limits.so` is the code that reads it.

### Check that `pam_limits.so` is switched on

Look for the module in the common PAM files:

<!-- astrona:playground:renew -->

```sh
grep -n pam_limits /etc/pam.d/common-session /etc/pam.d/login /etc/pam.d/sshd 2>/dev/null
```

You want a line such as `session required pam_limits.so` somewhere in the chain. This is the step people miss most often. If the module is missing or commented out for the service that handles the login, every `limits.conf` line on the ship is correct and enforced by nothing.

### Write the drop-in and check it from a fresh session

Save this as `/etc/security/limits.d/jackie-nproc.conf` (for example with `sudo nano`):

```text
jackie  hard  nproc  150
```

Nothing needs reloading: `pam_limits.so` reads the file the next time a session opens. Then check the result. Confirm the module line and open a **fresh** login shell as `jackie`:

```sh
grep -n pam_limits /etc/pam.d/common-session
sudo -u jackie -i ulimit -Hu
```

Expect something like:

```text
25:session required                        pam_limits.so
150
```

`pam_limits.so` is in `common-session`, so the drop-in is live. A fresh login shell now reports a hard `nproc` of `150`, so `jackie` can no longer raise her soft limit past it. A shell she already had open would still show the old value, because `pam_limits.so` only applies limits when a session starts.

## Retiring the old line

With the real mechanism in place, remove the `~/.bashrc` hack so there are not two sources of truth for one limit.

### Delete the `ulimit` line

Delete the line from `jackie`'s `~/.bashrc`:

```sh
sudo sed -i '/ulimit -Su/d' /home/jackie/.bashrc
```

`sed -i '/pattern/d'` finds every line that contains the pattern and deletes it in place.

> [!TIP]
> When you change PAM or limits, keep your current `root` session open and test from a new one. If something goes wrong, you still have a way back in.

## Common pitfalls

> [!WARNING]
> - **The `limits.d` line is written, but the limit is not applied.** Check that `pam_limits.so` is in the `session` stack of the *right* PAM service (`sshd`, `login`, `common-session`). Without it the file does nothing.
> - **Testing from the shell you edited in.** The limit only takes effect when a session starts. Always check from a new login.
> - **Leaving the old `~/.bashrc` line.** Two places now set the same limit, and the next person cannot tell which one counts.
