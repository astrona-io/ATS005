# Solution Walkthrough

This walkthrough sets one variable ship-wide for login and non-login shells, and one personal variable for `candidate` only. Run every command on the lab machine (`astrona ssh ats-005-lab-031`), as `root` unless a step says otherwise (become `root` with `sudo -i`).

---

## Step 1: Set a system-wide variable in /etc/environment

`COMPANY_PROXY=http://proxy.internal:3128` must be set for every user, and it must reach both **login shells** (such as an SSH connection) and **non-login shells** (such as a second terminal or a sub-shell).

The right file for this is `/etc/environment`, the ship-wide notice board.

*   **How `/etc/environment` works:** the PAM environment module (`pam_env.so`) parses this file when a session is set up. PAM (Pluggable Authentication Modules) is the checklist every login passes through. The file is not a shell script; it is a plain text file read before any shell starts.
*   **Format rules:** because it is parsed and not run, **never** use shell keywords such as `export`, and you do not need quotes. It only accepts bare `KEY=VALUE` lines.
*   **Why `/etc/profile.d/` is the wrong tool here:** scripts in `/etc/profile.d/` are sourced for **login shells** only. If a user who is already logged in opens a new shell tab or a sub-shell (a non-login interactive shell), those scripts never run.

Append the variable to `/etc/environment`:

```bash
sudo tee -a /etc/environment <<'EOF'
COMPANY_PROXY=http://proxy.internal:3128
EOF
```

*   `sudo tee -a`: the `-a` (append) option is **critical**. It adds the line to the end of `/etc/environment` without overwriting what is already there.

---

## Step 2: Check the system-wide variable in a fresh session

Variables from `/etc/environment` are loaded only when a session starts. A terminal that was open before you edited the file does not show the new variable.

Start a brand-new login session as `candidate`:

```bash
su - candidate
```

*   `su -`: the hyphen (`-`) starts a clean login session, so PAM sets up a new environment and reads `/etc/environment`.

Print the environment and look for the variable:

```bash
env | grep COMPANY_PROXY
```

*   **Expected Output:** `COMPANY_PROXY=http://proxy.internal:3128`

Go back to your `root` shell for the next steps:

```bash
exit
```

---

## Step 3: Set a personal editor for candidate only

`EDITOR=vim` must apply only to `candidate`, and leave `root` and every other user unchanged.

Log in as `candidate` again:

```bash
su - candidate
```

Write the preference into `candidate`'s personal login profile, `~/.bash_profile`:

```bash
echo 'export EDITOR=vim' >> ~/.bash_profile
```

*   `>>` appends the line to the end of the file.
*   **Why `export` is required here:** unlike `/etc/environment`, `~/.bash_profile` is a real bash script that runs when the shell starts. `export` makes the variable available to the programs this shell starts (such as `git` or `visudo`).

---

## Step 4: Reload and confirm the environment

Load the change into your current shell without logging out:

```bash
source ~/.bash_profile
echo "$EDITOR"
```

*   `source` runs the file inside the current shell, so its variables land in this shell straight away. It should print `vim`.

---

## Step 5: Confirm no other accounts were changed

To prove that no other account was touched, search the other profile files and confirm `EDITOR` was written only in `candidate`'s home:

```bash
grep -rl EDITOR /home/*/.bash_profile /home/*/.bash_login /home/*/.profile /root/.bash_profile 2>/dev/null
```

*   `grep -rl`: `-r` (recursive) searches directory paths, and `-l` lists only the names of files that match.
*   **Expected Output:** only `/home/candidate/.bash_profile`.

---

## Step 6: Check your work

Run these commands in a fresh login session before you send the lab for grading:

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

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-031
```
