# Solution Walkthrough

This guide explains how to configure a system-wide environment variable that applies to *both* login and non-login interactive shell sessions, and how to configure personal editor preferences for a single user account.

---

## Step 1: Set a system-wide variable via /etc/environment

We want `COMPANY_PROXY=http://proxy.internal:3128` to be defined system-wide, and it must reach both **login shells** (like SSH connections) and **non-login shells** (like launching a secondary terminal or running a sub-shell).

The correct tool for this task is the `/etc/environment` configuration file.
*   **How `/etc/environment` works:** This file is parsed by the PAM environment module (`pam_env.so`) during session establishment. It is not an active shell script; instead, it is a plain text configuration file read before any shell is even started.
*   **Syntax rules:** Since it is parsed rather than executed, you must **never** use shell keywords like `export`, and you do not need to wrap values in quotes. It only accepts raw, bare `KEY=VALUE` pairs.
*   **Why `/etc/profile.d/` is the wrong tool here:** Scripts inside `/etc/profile.d/` are only sourced for **login shells**. If a user is already logged in and opens a new shell tab or sub-process (a non-login interactive shell), those scripts will never execute!

Append the variable to `/etc/environment`:
```bash
sudo tee -a /etc/environment <<'EOF'
COMPANY_PROXY=http://proxy.internal:3128
EOF
```
*   `sudo tee -a`: The `-a` (append) flag is **critical**. It appends the input to the end of the `/etc/environment` file without overwriting its existing contents.

---

## Step 2: Verify the system-wide variable in a fresh session

Environment variables set via `/etc/environment` are loaded only at the moment a session starts. Any active terminal session created before you edited the file will not display the new variable.

To verify, start a brand-new login session as the `candidate` user:
```bash
su - candidate
```
*   `su -`: The hyphen (`-`) tells the system to initialize a clean login session, forcing PAM to establish a new environment and load `/etc/environment` properly.

Print the environment to confirm:
```bash
env | grep COMPANY_PROXY
```
*   **Expected Output:** `COMPANY_PROXY=http://proxy.internal:3128`

Exit back to your administrative shell to complete the remaining tasks:
```bash
exit
```

---

## Step 3: Set a personal editor for candidate only

We want `EDITOR=vim` to apply only to the `candidate` user account, leaving the configuration for root and all other system users untouched.

Log back into the `candidate` user account:
```bash
su - candidate
```

We will write this personal environment preference into `candidate`'s personal login profile file (`~/.bash_profile`):
```bash
echo 'export EDITOR=vim' >> ~/.bash_profile
```
*   `>>`: Appends the line to the end of the file.
*   **Why `export` is required here:** Unlike `/etc/environment`, `~/.bash_profile` is an active bash script sourced during shell startup. We must use `export` to make the variable available to any programs (like `git` or `visudo`) started by this shell.

---

## Step 4: Reload and confirm the environment

To apply the changes immediately to your current active shell session without logging out:
```bash
source ~/.bash_profile
echo "$EDITOR"
```
*   `source`: Sourced execution loads the variables directly into the current shell process.

---

## Step 5: Confirm no other accounts were modified

To prove we complied with the "without affecting other accounts" constraint, we can search all other home directory profile files to confirm `EDITOR` was only written inside `candidate`'s folder:
```bash
grep -rl EDITOR /home/*/.bash_profile /home/*/.bash_login /home/*/.profile /root/.bash_profile 2>/dev/null
```
*   `grep -rl`: `-r` (recursive) searches directory paths, and `-l` (files with matches) outputs only the names of files containing the search pattern.
*   **Expected Output:** Only `/home/candidate/.bash_profile` should be returned.

---

## Verification

Run these commands in a fresh login session to verify your work before running the final validation suite:

```bash
# Verify both variables exist in candidate's environment
su - candidate -c 'env | grep -E "COMPANY_PROXY|EDITOR"'
# Expect:
# COMPANY_PROXY=http://proxy.internal:3128
# EDITOR=vim

# Verify that the system-wide variable was NOT duplicated inside user dotfiles
grep -rn COMPANY_PROXY /home/*/.bashrc /home/*/.bash_profile /home/*/.profile 2>/dev/null
# Expect: no output (confirming it is clean and isolated in /etc/environment)
```
Once verified, run the local validation suite to pass the lab!
