# Solution Walkthrough

This guide explains how to find active session limits, replace unstable personal script-based overrides with secure, PAM-enforced system boundaries, and enforce concurrent session limits for entire user groups.

---

## Step 1: Discover jackie's current soft limit value

A previous admin attempted to enforce a process limit (`nproc`) on user `jackie` by writing a line in her personal `.bashrc` profile. This is bad practice:
1.  `.bashrc` is only executed for interactive bash shells. Non-interactive sessions (such as cron jobs or remote API tasks) bypass it.
2.  It set only a **soft** limit. Soft limits are advisory and can be increased by the user at will. We want to configure a PAM-enforced **hard** limit (which only root can increase).

First, inspect jackie's `.bashrc` file to find where the `ulimit` is defined:
```bash
sudo grep -n ulimit /home/jackie/.bashrc
```

Let's query the system directly to find the exact numerical soft limit currently applied to jackie's environment:
```bash
sudo -u jackie -i ulimit -Sp
```
*   `sudo -u jackie -i`: Opens an interactive login session as `jackie`, ensuring `.bashrc` is fully sourced.
*   `ulimit -Sp`: Displays the active **soft** (`-S`) process limit (`-p` / `nproc`). Note down this number (for example, `175`).

---

## Step 2: Enforce the hard limit via PAM configuration

Rather than modifying the global `/etc/security/limits.conf` directly, we will write a custom configuration inside `/etc/security/limits.d/`. This keeps our customizations modular, isolated, and easy to review.

Create and open the limit configuration drop-in file:
```bash
sudo vi /etc/security/limits.d/jackie-nproc.conf
```
Add the following line (replace `175` with the actual number you discovered in Step 1 if it differs):
```text
jackie hard nproc 175
```
Let's break down this syntax:
*   `jackie`: The target user account.
*   `hard`: Sets a hard limit that cannot be bypassed by the user.
*   `nproc`: Specifies the maximum number of concurrent processes the user can run.

---

## Step 3: Remove the old .bashrc hack

Since PAM now handles limits securely at session startup, remove the old line from jackie's `.bashrc` file to clean up the environment:
```bash
sudo sed -i '/ulimit -Sp/d' /home/jackie/.bashrc
```
*   `sed -i '/pattern/d'`: Searches for the line containing `ulimit -Sp` and deletes (`d`) it in-place (`-i`).

---

## Step 4: Confirm pam_limits.so is enabled in PAM

Limits defined in `/etc/security/limits.conf` and `/etc/security/limits.d/` are enforced by a Pluggable Authentication Module (PAM) named `pam_limits.so`. If this module is not loaded during session setup, our limits will be ignored.

Verify that the module is enabled in your authentication chains:
```bash
grep -n pam_limits /etc/pam.d/common-session /etc/pam.d/login /etc/pam.d/sshd 2>/dev/null
```
*   **What to look for:** You should see a line like `session required pam_limits.so` in one or more of these files. On modern Ubuntu systems, this is pre-configured out-of-the-box.

---

## Step 5: Enforce operators maxlogins

We want to restrict every individual member of the `operators` group to a maximum of `1` active login session at any time.

First, verify that the group exists:
```bash
getent group operators
```

Create a dedicated drop-in file:
```bash
sudo vi /etc/security/limits.d/operators-maxlogins.conf
```
Add the following rule:
```text
@operators hard maxlogins 1
```
Let's break down this syntax:
*   `@operators`: The `@` symbol tells PAM that the target is a **group** instead of a single user account.
*   `hard`: Enforces a strict, unbypassable hard ceiling.
*   `maxlogins`: Restricts the maximum number of concurrent login sessions.

---

## Verification

Confirm your configurations are correct before concluding the lab:

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
Once verified, run the local validation suite to pass the lab!
