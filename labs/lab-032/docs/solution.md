# Solution Walkthrough

This walkthrough adds `~/work` to the *end* of `candidate`'s `PATH`, saves it in a login-shell file, and proves that a decoy `ls` never wins. `PATH` is the list of directories (decks) the shell searches, from left to right, to find a command by name. Run every command on the lab machine (`astrona ssh ats-005-lab-032`), as `root` until you switch to `candidate` (become `root` with `sudo -i`).

---

## Step 1: Look at the current PATH and how commands resolve

Before you change anything, look at the environment as `candidate` sees it.

Start a clean login session as `candidate`:

```bash
su - candidate
```

*   `su -`: the hyphen (`-`) is **critical**. It starts a real **login shell** for the user, which loads their profile files and environment. Without it, you would switch users but keep your previous environment.

Print the search path and ask how `ls` resolves:

```bash
echo $PATH
type ls
```

*   `type ls` reports how the shell resolves a typed command: a built-in command, an alias, or a file path.

---

## Step 2: Append ~/work to candidate's PATH permanently

Add the line to `candidate`'s personal `~/.bash_profile`:

```bash
echo 'export PATH="$PATH:$HOME/work"' >> ~/.bash_profile
```

Here is what the line does:

*   `>>` **appends** the line to the end of the file. Never use a single `>`: it overwrites the whole profile.
*   `PATH="$PATH:$HOME/work"` puts `$HOME/work` at the *end* of the existing `PATH` list.
*   **Why appending matters (no shadowing):** the shell searches `PATH` from left to right. With the system directories (`$PATH`) *before* `$HOME/work`, real commands such as `ls` or `id` are always found first. If you put your directory first (for example `export PATH="$HOME/work:$PATH"`), anyone who drops a script named `ls` into `~/work` would take over that command.
*   **Why `~/.bash_profile` works:** a login shell reads the first of `~/.bash_profile`, `~/.bash_login` and `~/.profile` that exists. Once `~/.bash_profile` exists, it is the one that counts.

Load the profile into your current shell:

```bash
source ~/.bash_profile
```

*   `source` (or its short form `.`) runs the file inside the current shell, so the new `PATH` applies straight away without logging out.

---

## Step 3: Run the tool by name

With `~/work` in `PATH`, run the script by name alone:

```bash
helper-tool
```

*   **Expected Output:** `helper-tool from ~/work` (proving the `PATH` is set correctly).

---

## Step 4: Prove a decoy cannot shadow the real command

Now prove that a decoy script named `ls` in `~/work` is ignored, and the real system `ls` still runs.

Save this as `~/work/ls`:

```bash
#!/bin/bash
echo "decoy ls - should never run"
```

Make it executable:

```bash
chmod +x ~/work/ls
```

Clear the shell's memory of command locations:

```bash
hash -r
```

*   `hash -r`: bash remembers where it found each command, to save searching. After you change `PATH` or add files, run `hash -r` so bash searches again.

Ask how `ls` resolves now:

```bash
type ls
```

*   **Expected Output:** `ls is aliased to...` or `ls is /bin/ls`. The shell resolved the command to the real location, not the decoy in `~/work`.

Run it:

```bash
ls
```

You should see a normal directory listing, not the decoy's message.

Remove the decoy:

```bash
rm ~/work/ls
```

---

## Step 5: Check your work

Check every change before you send the lab for grading:

```bash
# Check that the export statement exists in the profile
grep work ~/.bash_profile

# Confirm /home/candidate/work is listed near/at the end of the PATH variable
echo $PATH | tr ':' '\n'

# Test executing the script
helper-tool
```

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-032
```
