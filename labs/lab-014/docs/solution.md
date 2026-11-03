# Solution Walkthrough

This walkthrough writes one drop-in file for the standing orders. A drop-in is an extra page clipped to `/etc/sudoers`, kept in `/etc/sudoers.d/`. Run every command on the lab machine (`astrona ssh ats-005-lab-014`).

---

## Step 1: Look at the crew first

Check that the group and the users are what the task says:

```bash
getent group webops
id cleo
```

- `getent group webops` lists the members of `webops`. You should see `anna` and `ben`.
- `id cleo` shows that `cleo` is not in that group.

---

## Step 2: Open the drop-in with visudo

Create the file through the clerk, so a typo can never be saved:

```bash
sudo visudo -f /etc/sudoers.d/webops
```

- `visudo -f <path>` edits one file and checks it when you save.
- A file made this way gets owner `root:root` and mode `0440`.
- The name `webops` has no dot. A name with a dot would be skipped by `sudo`.

---

## Step 3: Write the rules

In the editor, write these three lines, then save and quit:

```text
Cmnd_Alias SERVICE_CMDS = /usr/bin/systemctl status ssh, /usr/bin/systemctl restart ssh
%webops ALL=(root) NOPASSWD: SERVICE_CMDS
cleo ALL=(root) /usr/bin/journalctl -u ssh
```

- The first line gives the two commands the name `SERVICE_CMDS`.
- `%webops` means every member of the group, so `anna` and `ben` both get the rule. `NOPASSWD:` means no password.
- The `cleo` line has no `NOPASSWD:`, so `sudo` asks for her own password.
- Nobody gets `ALL`, so the grants stay as narrow as the task asks.

---

## Step 4: Check the file, its owner and its mode

Check every sudoers file and look at the new one:

```bash
sudo visudo -c
sudo ls -l /etc/sudoers.d/webops
```

- `visudo -c` must say that the files parse without an error.
- `ls -l` should show `-r--r-----` and `root root`. If the mode is different, run `sudo chmod 0440 /etc/sudoers.d/webops` and `sudo chown root:root /etc/sudoers.d/webops`.

---

## Step 5: Prove what each user may run

List the rules of each user without becoming them:

```bash
sudo -l -U anna
sudo -l -U ben
sudo -l -U cleo
```

- `anna` and `ben` should each show `(root) NOPASSWD:` with the two `systemctl` commands.
- `cleo` should show the `journalctl` command and no `NOPASSWD`.

Then prove one refusal. The `-n` option makes `sudo` fail at once instead of asking for a password:

```bash
sudo -u anna sudo -n /usr/bin/systemctl stop ssh; echo "exit: $?"
```

- The command is refused and `exit: 1` is printed, because `stop` is not in the alias.

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-014
```
