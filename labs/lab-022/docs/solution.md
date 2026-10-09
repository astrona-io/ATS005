# Solution Walkthrough

This walkthrough finds the number in the coworker's fix, turns it into a hard limit that PAM (Pluggable Authentication Modules, the checklist every login passes through) enforces, removes the old line, and caps the `operators` group to one login each. Run every command on the lab machine (`astrona ssh ats-005-lab-022`).

---

## Step 1: Find jackie's soft limit value

A coworker tried to limit the number of processes (`nproc`) for `jackie` with a line in her personal `.bashrc`. That is a weak fix, for two reasons:

1. `.bashrc` only runs for interactive bash shells. Non-interactive sessions, such as cron jobs or remote scripted commands, skip it.
2. It sets only a **soft** limit. A user can raise her own soft limit whenever she likes. You want a **hard** limit, enforced by PAM, that only `root` can raise.

First, look at the line in jackie's `.bashrc`:

```bash
sudo grep -n ulimit /home/jackie/.bashrc
```

The number at the end of the `ulimit -Sp` line is the value the coworker meant as jackie's soft process limit (for example, `175`). This is the number the task asks you to keep, and the grader compares your hard limit with it.

You may also see this check, which reads the value from a login shell:

```bash
sudo -u jackie -i ulimit -Sp
```

- `sudo -u jackie -i` opens an interactive login shell as `jackie`, so her `.bashrc` is read.
- `ulimit -Sp` asks for a **soft** (`-S`) value.

Be careful with this one. In bash, the `-p` option of `ulimit` is the pipe size, not the process limit; the process limit is `-u` (`ulimit -Su`). So this command does not print the process limit, and the coworker's `ulimit -Sp` line never set one. Take the number from the `.bashrc` line itself.

---

## Step 2: Set the hard limit through PAM

Do not edit the big `/etc/security/limits.conf` file. Write your own drop-in file in `/etc/security/limits.d/`. That keeps the change separate and easy to review.

Create and open the drop-in file:

```bash
sudo vi /etc/security/limits.d/jackie-nproc.conf
```

Add this line (replace `175` with the number you found in Step 1 if it is different):

```text
jackie hard nproc 175
```

Here is what each column means:

- `jackie`: the user the line applies to.
- `hard`: a hard limit, which the user cannot raise.
- `nproc`: the maximum number of processes the user may run at once.
- `175`: the number.

---

## Step 3: Remove the old .bashrc line

PAM now applies the limit at every session start, so remove the old line from jackie's `.bashrc`:

```bash
sudo sed -i '/ulimit -Sp/d' /home/jackie/.bashrc
```

- `sed -i '/pattern/d'` finds every line that contains `ulimit -Sp` and deletes (`d`) it in place (`-i`).

---

## Step 4: Confirm that pam_limits.so is switched on

The lines in `/etc/security/limits.conf` and `/etc/security/limits.d/` are applied by a PAM module called `pam_limits.so`. If that module does not run when a session opens, your limit is ignored.

Look for the module in the PAM files:

```bash
grep -n pam_limits /etc/pam.d/common-session /etc/pam.d/login /etc/pam.d/sshd 2>/dev/null
```

You should see a line such as `session required pam_limits.so` in one or more of these files. On Ubuntu it is switched on out of the box.

---

## Step 5: Cap the operators group to one login each

Every member of `operators` may have at most `1` login session at a time.

First, check that the group exists and see who is in it:

```bash
getent group operators
```

Create a separate drop-in file:

```bash
sudo vi /etc/security/limits.d/operators-maxlogins.conf
```

Add this line:

```text
@operators hard maxlogins 1
```

Here is what each column means:

- `@operators`: the `@` tells PAM that the target is a **group**, not a single user.
- `hard`: a hard ceiling the members cannot raise.
- `maxlogins`: the maximum number of login sessions open at the same time.
- `1`: the number.

---

## Step 6: Check your work

Check every change before you send the lab for grading:

```bash
# Verify jackie's process limit configurations
sudo grep nproc /etc/security/limits.d/jackie-nproc.conf
sudo grep ulimit /home/jackie/.bashrc   # Expect no output (confirming deletion)

# Run a test session as jackie to verify limits
sudo -u jackie -i bash -c 'ulimit -Hp; ulimit -Sp'
# Expect: both output lines to display your configured number (e.g. 175)

# Verify operators maxlogins rule is defined
sudo grep maxlogins /etc/security/limits.d/operators-maxlogins.conf
```

As in Step 1, `ulimit -Hp` and `ulimit -Sp` report the pipe size in bash, not the process limit. To see the new hard process limit from a fresh login, use `-u` instead:

```bash
sudo -u jackie -i ulimit -Hu
```

It should print the number you wrote in `jackie-nproc.conf`.

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-022
```
