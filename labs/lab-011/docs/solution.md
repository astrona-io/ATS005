# Solution Walkthrough

This walkthrough fixes `user1`, creates `user2`, and grants `user2` one exact `sudo` command. Run every command on the lab machine (`astrona ssh ats-005-lab-011`), as the normal user with `sudo`.

---

## Step 1: Create the target groups and the parent directory

Before you change any account, make sure the groups and the destination path exist.

```bash
sudo groupadd dev 2>/dev/null
sudo groupadd op 2>/dev/null
sudo mkdir -p /home/accounts
```

- `groupadd dev 2>/dev/null` creates the `dev` group. If the group already exists, `groupadd` prints an error; `2>/dev/null` throws that message away to keep the screen clean.
- `mkdir -p /home/accounts` creates the parent directory. `-p` (parents) creates any missing directories above it and does not complain if the directory is already there. `usermod -m` needs this parent, because it does not create it.

---

## Step 2: Move user1 to the new group and home

Set `user1`'s primary group to `dev`, point the home at the new path, and move the files, all in one command:

```bash
sudo usermod -g dev -d /home/accounts/user1 -m user1
```

- `-g dev` changes `user1`'s **primary** group to `dev`.
- `-d /home/accounts/user1` sets the new home path.
- `-m` **moves** the contents. `-d` on its own only changes the path written in `/etc/passwd`. `-m` moves every file from the old home (`/home/user1`) to the new path. Without it, `user1` would log in to an empty home directory while their files stayed at the old path.

---

## Step 3: Create user2

Add the new account with its home, supplementary groups and shell:

```bash
sudo useradd -m -d /home/accounts/user2 -G dev,op -s /bin/bash user2
```

- `-m` creates the home directory.
- `-d /home/accounts/user2` sets the exact home path.
- `-G dev,op` (capital `G`) sets the **supplementary** groups. On a new account there is no old list to lose, so a comma-separated list is safe.
- `-s /bin/bash` sets `/bin/bash` as the login shell instead of a basic shell such as `/bin/sh`.

---

## Step 4: Grant user2 one exact sudo command

`user2` must run exactly one script as `root` with no password. First find where `bash` is installed:

```bash
which bash
```

Usually this is `/usr/bin/bash`. Write the rule in a drop-in file under `/etc/sudoers.d/` with `visudo`, which checks the syntax before it saves:

```bash
sudo visudo -f /etc/sudoers.d/user2-dangerous-script
```

Add this line exactly, with the path `which bash` reported:

```text
user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh
```

Here is what each piece means:

- `user2`: the user the rule applies to.
- `ALL=`: the rule is active on all hosts.
- `(root)`: the command runs as `root`.
- `NOPASSWD:`: `sudo` does not ask `user2` for a password for this command.
- `/usr/bin/bash /root/dangerous.sh`: the exact command allowed. Any other command, or the same command with other arguments, is refused.

Save and quit. Then set the owner and permissions that `sudo` requires, and check every rules file:

```bash
sudo chmod 0440 /etc/sudoers.d/user2-dangerous-script
sudo chown root:root /etc/sudoers.d/user2-dangerous-script
sudo visudo -c
```

- `chmod 0440` lets only `root` and the `root` group read the file, and nobody write to it. `sudo` ignores a rules file that others can write to.
- `visudo -c` checks the main file and every drop-in, and reports whether each one parsed correctly.

---

## Step 5: Check your work

Check every change by hand before you send the lab for grading:

```bash
# Verify user1 relocation
id user1                      # Primary group should now be dev
getent passwd user1            # Home directory field should show /home/accounts/user1
ls -la /home/accounts/user1   # Confirm original files are present

# Verify user2 creation
id user2                      # Groups should include dev and op
sudo -l -U user2              # Confirm the exact NOPASSWD sudo rule is listed
su - user2 -c "sudo -n bash /root/dangerous.sh" # Test the sudo rule (should run without asking for a password)
```

`id user1` should show `gid=` with `dev`, and the new home should hold `user1`'s old files. `sudo -l -U user2` should list exactly one `NOPASSWD` command. The last command should run the script as `root` without asking for a password.

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-011
```
