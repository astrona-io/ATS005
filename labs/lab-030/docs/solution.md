# Solution Walkthrough

This guide explains how to configure environment variables with different system-wide and user-specific scopes, and how to safely extend the command search PATH without shadowing vital system utilities.

---

## Step 1: Set a system-wide variable for login shells

We want `ONBOARD_PORTAL=https://portal.internal/onboarding` to be available system-wide for every user, but only when they log in (such as starting an SSH connection or console login session).

The best tool for this is a script inside `/etc/profile.d/`. Scripts in `/etc/profile.d/` are sourced by `/etc/profile` when a login shell initializes. Since it is run by the shell interpreter, we can use standard shell scripting syntax (like `export`).

Create the drop-in script:
```bash
sudo tee /etc/profile.d/onboard.sh > /dev/null <<'EOF'
export ONBOARD_PORTAL="https://portal.internal/onboarding"
EOF
```
*   `sudo tee`: Writes to a file requiring root privileges while discarding the standard output redirect (`> /dev/null`).
*   `export`: In Linux, variables are local to the current shell unless they are exported. The `export` keyword marks the variable, making it available to any subprocesses or programs launched by that shell session.

Set read permissions so all users can source the script at login:
```bash
sudo chmod 644 /etc/profile.d/onboard.sh
```

---

## Step 2: Set a personal editor for candidate only

We want `EDITOR=nano` to apply only to the `candidate` user account, without modifying the environment for root or other users.

Login to the `candidate` user shell:
```bash
su - candidate
```
*   `su -`: The hyphen (`-`) is **critical**. It tells the system to start a clean, genuine **login shell** for the user, fully loading their profile files and environment variables. Without the hyphen, you would switch users but inherit your previous environment!

We will append this environment variable to `candidate`'s personal `~/.bash_profile`:
```bash
echo 'export EDITOR=nano' >> ~/.bash_profile
```
*   `>>`: The double redirect **appends** the line to the end of the file.
*   **Warning:** Never use a single redirect (`>`), as it will instantly overwrite and wipe out the entire file!

Reload the profile dynamically into the current active session:
```bash
source ~/.bash_profile
```
*   `source` (or the shortcut `.`): Sources and executes the profile script in the current active shell process, updating the environment immediately without requiring you to log out and back in.

---

## Step 3: Append ~/bin to candidate's PATH safely

The `PATH` environment variable is a colon-separated list of directories where the system looks for executable commands when you type them.

```bash
echo 'export PATH="$PATH:$HOME/bin"' >> ~/.bash_profile
source ~/.bash_profile
```
Let's analyze the syntax:
*   `PATH="$PATH:$HOME/bin"`: This **appends** candidate's personal tool path (`$HOME/bin`) to the *end* of the existing `$PATH`.
*   **Why appending is critical (No Shadowing):** Linux searches directories listed in `PATH` from left to right. By placing the system directories (`$PATH`) *before* the personal directory (`$HOME/bin`), standard system utilities (such as `ls` or `id`) will always be found and run first. If you prepended your directory (e.g. `export PATH="$HOME/bin:$PATH"`), anyone who drops a script named `ls` or `id` into `~/bin` would hijack that command, posing a major security and system stability risk!

Test that candidate's custom tool now runs:
```bash
deploy-helper
```

---

## Step 4: Prove path shadowing prevention

We want to prove that if a decoy script named `id` is placed inside `~/bin`, the system will ignore it and continue running the safe `/usr/bin/id` system command.

Create a decoy script:
```bash
cat > ~/bin/id << 'EOF'
#!/bin/bash
echo "decoy id - should never run"
EOF
chmod +x ~/bin/id
```

Clear the shell's command resolution cache:
```bash
hash -r
```
*   `hash -r`: Bash caches the absolute paths of previously executed commands to save search time. If you alter the `PATH` variable or add files, you must run `hash -r` to clear this lookup cache and force Bash to perform a fresh filesystem search.

Query how the command is resolved:
```bash
type id
```
*   **Expected Output:** `id is /usr/bin/id` (or `/bin/id`). This confirms the system resolved the command to the safe, standard location.

Run the command to ensure the system is secure:
```bash
id
```
The standard user identification output should print, rather than the decoy's message.

Clean up the decoy script to restore a pristine state:
```bash
rm ~/bin/id
```

---

## Verification

Verify that all three parts are configured correctly before completing the lab:

```bash
# Verify system-wide variable and personal variable
su - candidate -c 'env | grep -E "ONBOARD_PORTAL|EDITOR"'
# Expect:
# ONBOARD_PORTAL=https://portal.internal/onboarding
# EDITOR=nano

# Inspect candidate's PATH variable structure
su - candidate -c 'echo $PATH | tr ":" "\n"'
# Expect: Confirm /home/candidate/bin is listed at the very end of the list

# Verify helper tool runs
su - candidate -c 'deploy-helper'
```
Once verified, run the local validation suite to pass the lab!
