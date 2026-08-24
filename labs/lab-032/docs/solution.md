# Solution Walkthrough

This guide explains how to persist command search PATH variables for a specific user, and how to safely extend search paths without shadowing vital system binaries.

---

## Step 1: Inspect the current PATH and command resolution

Before changing anything, let's explore the current environment from the perspective of the `candidate` user account.

Switch to a clean login session for the `candidate` user:
```bash
su - candidate
```
*   `su -`: The hyphen (`-`) is **critical**. It tells the system to start a clean, genuine **login shell** for the user, fully loading their profile files and environment variables. Without the hyphen, you would switch users but inherit your previous environment!

Verify their current search `PATH` and command locations:
```bash
echo $PATH
type ls
```
*   `type ls`: Reports how a typed command is resolved by the shell (e.g. built-in, alias, or filesystem binary path).

---

## Step 2: Append ~/work to candidate's PATH persistently

The `PATH` environment variable is a colon-separated list of directories where the system looks for executable commands when you type them. We want to add candidate's custom tool path (`~/work`) to their environment.

We will append this environment variable to `candidate`'s personal `~/.bash_profile` file:
```bash
echo 'export PATH="$PATH:$HOME/work"' >> ~/.bash_profile
```
Let's analyze the syntax:
*   `>>`: The double redirect **appends** the line to the end of the file. (Never use a single `>` redirect, as it will overwrite and erase your entire profile!)
*   `PATH="$PATH:$HOME/work"`: This **appends** candidate's personal tool path (`$HOME/work`) to the *end* of the existing `$PATH` list.
*   **Why appending is critical (No Shadowing):** Linux searches directories listed in `PATH` from left to right. By placing the system directories (`$PATH`) *before* the personal directory (`$HOME/work`), standard system utilities (such as `ls` or `id`) will always be found and run first. If you prepended your directory (e.g. `export PATH="$HOME/work:$PATH"`), anyone who drops a script named `ls` into `~/work` would hijack that command, posing a major security and system stability risk!

Reload the profile dynamically into your current active shell:
```bash
source ~/.bash_profile
```
*   `source` (or the shortcut `.`): Sourced execution loads variables directly into the current active shell process, updating the environment immediately without requiring you to log out and back in.

---

## Step 3: Run the custom tool by name

Now that `~/work` is registered in candidate's `PATH`, try executing their script by name alone:
```bash
helper-tool
```
*   **Expected Output:** `helper-tool from ~/work` (proving the PATH is correctly configured).

---

## Step 4: Prove path shadowing prevention

We want to prove that if a decoy script named `ls` is placed inside `~/work`, the system will ignore it and continue running the safe `/bin/ls` system command.

Create a decoy script inside `~/work`:
```bash
cat > ~/work/ls << 'EOF'
#!/bin/bash
echo "decoy ls - should never run"
EOF
chmod +x ~/work/ls
```

Clear the shell's command resolution cache:
```bash
hash -r
```
*   `hash -r`: Bash caches the absolute paths of previously executed commands to save search time. If you alter the `PATH` variable or add files, you must run `hash -r` to clear this lookup cache and force Bash to perform a fresh filesystem search.

Query how the command is resolved:
```bash
type ls
```
*   **Expected Output:** `ls is aliased to...` or `ls is /bin/ls`. This confirms the system resolved the command to the safe, standard location instead of the decoy inside `~/work`.

Run the command to ensure the system is secure:
```bash
ls
```
The normal, standard directory listing output should print, rather than the decoy's message.

Clean up the decoy script to restore a pristine state:
```bash
rm ~/work/ls
```

---

## Verification

Verify that all changes were successfully applied before completing the lab:

```bash
# Check that the export statement exists in the profile
grep work ~/.bash_profile

# Confirm /home/candidate/work is listed near/at the end of the PATH variable
echo $PATH | tr ':' '\n'

# Test executing the script
helper-tool
```
Once verified, run the local validation suite to pass the lab!
