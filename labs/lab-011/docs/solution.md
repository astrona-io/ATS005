# Solution Walkthrough

This guide explains how to safely migrate existing users, provision new ones, and set up precise, limited privileges.

---

## Step 1: Create the target groups and directories

Before changing any user records, we need to ensure the groups and destination paths exist on the server.

```bash
sudo groupadd dev 2>/dev/null
sudo groupadd op 2>/dev/null
sudo mkdir -p /home/accounts
```
*   `groupadd dev 2>/dev/null`: This creates the `dev` group. If it already exists, the shell would normally throw a "group already exists" error. Redirecting standard error to `/dev/null` (`2>/dev/null`) keeps the terminal output clean.
*   `mkdir -p /home/accounts`: This creates the `/home/accounts` directory. The `-p` (parents) flag makes sure that any missing parent directories are created, and prevents errors if the directory is already present.

---

## Step 2: Relocate user1

We need to set `user1`'s primary group to `dev`, set their home directory to the new path, and move their physical files.

```bash
sudo usermod -g dev -d /home/accounts/user1 -m user1
```
Let's break down these flags:
*   `-g dev`: Modifies `user1`'s **primary** group to `dev`.
*   `-d /home/accounts/user1`: Defines the new path for the user's home directory.
*   `-m`: This is the **move** flag. It is critical because the `-d` option alone only changes the text pointer in `/etc/passwd`. The `-m` flag tells the system to physically copy and move all folders and files from the old home directory (`/home/user1`) to the new path, correcting permissions dynamically. Without `-m`, the user would log in and find their home directory completely empty!

---

## Step 3: Create user2

We need to add a brand-new user with a custom home directory, specific supplementary groups, and the `/bin/bash` shell.

```bash
sudo useradd -m -d /home/accounts/user2 -G dev,op -s /bin/bash user2
```
Let's break down these flags:
*   `-m`: Directs the system to create the user's home directory.
*   `-d /home/accounts/user2`: Sets the exact target path for the new home directory.
*   `-G dev,op`: The capital `-G` flag defines **supplementary** (additional) groups. Since this is a new user account, listing the groups as comma-separated values is perfectly safe.
*   `-s /bin/bash`: Sets `/bin/bash` as their default login shell instead of a basic shell like `/bin/sh`.

---

## Step 4: Configure scoped sudo access for user2

We want `user2` to be able to run exactly one script as root with no password prompt.
First, find where the `bash` binary is installed:
```bash
which bash
```
Usually, this returns `/usr/bin/bash`. We will write a custom rule inside `/etc/sudoers.d/` using `visudo`, which verifies our syntax before saving to prevent locks.

```bash
sudo visudo -f /etc/sudoers.d/user2-dangerous-script
```
Add the following line exactly:
```text
user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh
```
Let's break this rule down:
*   `user2`: The user to whom this rule applies.
*   `ALL=`: The rule is active on all hosts.
*   `(root)`: The command runs with root privileges.
*   `NOPASSWD:`: The system will not prompt `user2` for a password when running this command.
*   `/usr/bin/bash /root/dangerous.sh`: The precise command allowed. Any other command or argument variation will be denied.

Save and exit, then configure file ownership and permissions to meet sudo's security standards:
```bash
sudo chmod 0440 /etc/sudoers.d/user2-dangerous-script
sudo chown root:root /etc/sudoers.d/user2-dangerous-script
sudo visudo -c
```
*   `chmod 0440`: Restricts permissions so only root and the root group can read the file, and nobody can write to or execute it.
*   `visudo -c`: Compiles and checks all sudoers configuration files to confirm they are structurally valid.

---

## Verification

Always verify your system configuration manually to build confidence before running automated scripts:

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
