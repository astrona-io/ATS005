# Solution Walkthrough

This walkthrough sets one variable for every login shell with a `profile.d` script, one personal variable for `candidate`, and appends `~/bin` to `candidate`'s `PATH` so a decoy can never win. Run every command on the lab machine (`astrona ssh ats-005-lab-030`), as `root` until you switch to `candidate` (become `root` with `sudo -i`).

---

## Step 1: Set a system-wide variable for login shells

`ONBOARD_PORTAL=https://portal.internal/onboarding` must be available to every user, but only when they log in (for example an SSH connection or a console login).

The right tool is a script in `/etc/profile.d/`. `/etc/profile` sources every `.sh` file there when a login shell starts. Because the shell runs it, you can use normal shell syntax such as `export`.

Save this as `/etc/profile.d/onboard.sh`:

```bash
export ONBOARD_PORTAL="https://portal.internal/onboarding"
```

*   `export`: a shell variable stays inside the current shell unless it is exported. `export` makes it available to every program that shell starts.

Apply it, by giving every user permission to read the script at login:

```bash
sudo chmod 644 /etc/profile.d/onboard.sh
```

---

## Step 2: Set a personal editor for candidate only

`EDITOR=nano` must apply only to `candidate`, without changing the environment of `root` or any other user.

Log in as `candidate`:

```bash
su - candidate
```

*   `su -`: the hyphen (`-`) is **critical**. It starts a real **login shell** for the user, which loads their profile files and environment. Without it, you would switch users but keep your previous environment.

Append the variable to `candidate`'s personal `~/.bash_profile`:

```bash
echo 'export EDITOR=nano' >> ~/.bash_profile
```

*   `>>` **appends** the line to the end of the file.
*   **Warning:** never use a single `>`. It overwrites the whole file.

Load the profile into your current shell:

```bash
source ~/.bash_profile
```

*   `source` (or its short form `.`) runs the profile inside the current shell, so the change applies straight away without logging out.

---

## Step 3: Append ~/bin to candidate's PATH safely

`PATH` is the list of directories, separated by colons, that the shell searches for a command when you type its name.

```bash
echo 'export PATH="$PATH:$HOME/bin"' >> ~/.bash_profile
source ~/.bash_profile
```

Here is what the line does:

*   `PATH="$PATH:$HOME/bin"` puts `$HOME/bin` at the *end* of the existing `PATH`.
*   **Why appending matters (no shadowing):** the shell searches `PATH` from left to right. With the system directories (`$PATH`) *before* `$HOME/bin`, real commands such as `ls` or `id` are always found first. If you put your directory first (for example `export PATH="$HOME/bin:$PATH"`), anyone who drops a script named `ls` or `id` into `~/bin` would take over that command.
*   **Why `~/.bash_profile` and not `~/.profile`:** a login shell reads only the first of `~/.bash_profile`, `~/.bash_login` and `~/.profile` that exists. The stock Ubuntu `~/.profile` also contains a block that puts `~/bin` at the *front* of `PATH` when that directory exists, so a line in `~/.profile` alone could leave `~/bin` before `/usr/bin`. Once `~/.bash_profile` exists, `~/.profile` is no longer read by a login shell.

Check that `candidate`'s tool now runs by name:

```bash
deploy-helper
```

---

## Step 4: Prove a decoy cannot shadow the real command

Now prove that a decoy script named `id` in `~/bin` is ignored, and the real `/usr/bin/id` still runs.

Save this as `~/bin/id`:

```bash
#!/bin/bash
echo "decoy id - should never run"
```

Make it executable:

```bash
chmod +x ~/bin/id
```

Clear the shell's memory of command locations:

```bash
hash -r
```

*   `hash -r`: bash remembers where it found each command, to save searching. After you change `PATH` or add files, run `hash -r` so bash searches again.

Ask how `id` resolves now:

```bash
type id
```

*   **Expected Output:** `id is /usr/bin/id` (or `/bin/id`). The shell resolved the command to the real location.

Run it:

```bash
id
```

You should see the normal user identity output, not the decoy's message.

Remove the decoy:

```bash
rm ~/bin/id
```

---

## Step 5: Check your work

Check all three changes before you send the lab for grading:

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

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-030
```
