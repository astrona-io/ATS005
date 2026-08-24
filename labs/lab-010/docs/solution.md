# Solution Walkthrough

This walkthrough explains how to safely administer user accounts, groups, and permissions. Instead of memorizing commands, you'll learn the purpose of each utility and how to read its options.

---

## Part 1: Relocate analyst9

We need to change `analyst9`'s primary group to `finance`, move their home directory to `/home/accounts/analyst9`, and ensure their existing files are moved along with it.

### Step 1: Create the parent directory and group
Before moving the user, make sure the destination parent directory and the `finance` group exist.
```bash
sudo groupadd -f finance
sudo mkdir -p /home/accounts
```
*   `groupadd -f`: The `-f` (force) flag tells the system to succeed quietly and exit with success if the group already exists.
*   `mkdir -p`: The `-p` (parents) flag creates the `/home/accounts` directory and any missing parent directories, and won't throw an error if it already exists.

### Step 2: Relocate the user
Now, we'll use the `usermod` command to modify the user's properties.
```bash
sudo usermod -g finance -d /home/accounts/analyst9 -m analyst9
```
Let's break down these flags:
*   `-g finance`: This sets the user's **primary** group to `finance`. Any new files they create will be owned by this group.
*   `-d /home/accounts/analyst9`: This defines the new home directory path in `/etc/passwd`.
*   `-m`: This is the **move** flag. It is critical because `-d` only updates the text pointer in the configuration. `-m` tells the system to actually copy and move all physical files from the old home directory to the new path, correcting file ownerships. Without `-m`, the user would log into an empty directory!

---

## Part 2: Provision newhire9 with scoped sudo

We need to add a new user named `newhire9`, put them in the `finance` and `ops` groups, configure their home directory and shell, and give them a very specific sudo rule.

### Step 1: Create the ops group
```bash
sudo groupadd -f ops
```

### Step 2: Create the user
```bash
sudo useradd -m -d /home/accounts/newhire9 -G finance,ops -s /bin/bash newhire9
```
Let's break down these flags:
*   `-m`: Creates the home directory if it doesn't exist.
*   `-d /home/accounts/newhire9`: Sets the explicit path for the new home directory.
*   `-G finance,ops`: The capital `-G` flag specifies **supplementary** (additional) groups. Since this is a new user, we list them as comma-separated values.
*   `-s /bin/bash`: Sets `/bin/bash` as their default login shell instead of the system default (which might be a basic shell like `/bin/sh`).

### Step 3: Configure scoped sudo access
We want `newhire9` to run exactly one script as root without being prompted for a password.
First, verify where the `bash` binary lives on this system:
```bash
which bash
```
Usually, this returns `/usr/bin/bash` or `/bin/bash`. We'll write a custom rule inside `/etc/sudoers.d/`. Using the `sudoers.d` directory is safer than editing the main `/etc/sudoers` file because it keeps our custom rules modular and easy to delete.

Edit the rule file using `visudo`, which checks your file for syntax errors before saving. This prevents you from accidentally locking yourself out of sudo!
```bash
sudo visudo -f /etc/sudoers.d/newhire9-rotate-logs
```
Add the following line exactly:
```text
newhire9 ALL=(root) NOPASSWD: /usr/bin/bash /root/rotate-logs.sh
```
Let's break this rule down:
*   `newhire9`: The user this rule applies to.
*   `ALL=`: The rule applies to all hosts.
*   `(root)`: The command will run with root privileges.
*   `NOPASSWD:`: The system will not prompt `newhire9` for their password when running this command.
*   `/usr/bin/bash /root/rotate-logs.sh`: The exact command permitted. If they type anything else, even a slight variation, it will be denied.

Save and exit. Then, set the appropriate file permissions. Sudo requires that its configuration files have strict permissions and are owned by root:
```bash
sudo chmod 0440 /etc/sudoers.d/newhire9-rotate-logs
sudo chown root:root /etc/sudoers.d/newhire9-rotate-logs
sudo visudo -c
```
*   `chmod 0440`: Read-only access for owner and group, no access for anyone else.
*   `visudo -c`: Compiles and checks all sudoers files to ensure there are no syntax issues.

---

## Part 3: Group lifecycle

### Step 1: Create a group with a specific GID
```bash
sudo groupadd -g 6000 billing-team
```
*   `-g 6000`: This assigns the exact Group ID (GID) of `6000`. By default, Linux assigns the next available GID, but specifying it keeps user databases consistent across servers.

### Step 2: Add users to the group
```bash
sudo usermod -aG billing-team analyst9
sudo usermod -aG billing-team newhire9
```
*   `-aG`: The `-a` (append) and `-G` (groups) flags are **always** used together when modifying existing users. This adds the group to their supplementary list *without* removing any groups they already belong to. If you forget `-a`, `usermod` will replace all their existing supplementary groups with just `billing-team`!

### Step 3: Rename an existing group
We need to rename `legacy-billing` to `archive-billing` without changing its GID (`7000`) or losing its members.
```bash
sudo groupmod -n archive-billing legacy-billing
```
*   `groupmod -n`: The `-n` (new name) flag changes the name of the group. The underlying GID and the list of member users in `/etc/group` remain completely untouched.

### Step 4: Delete an unused group
```bash
sudo groupdel temp-scratch
```
*   `groupdel` removes the group from `/etc/group`. Make sure no files on the filesystem are still owned by this group GID, otherwise they will show up as owned by a raw number (e.g., `6000` instead of a name).

---

## Part 4: Lock audit2

If an account is under investigation, we want to lock it immediately to prevent logins, but we don't want to delete its files or configurations.
```bash
sudo passwd -l audit2
```
*   `passwd -l`: The `-l` (lock) flag locks the account's password by prepending a `!` or `!` to the encrypted password string in `/etc/shadow`. This invalidates the hash so no one can log in using password authentication, but preserves the original password so it can be unlocked later using `passwd -u`.

Let's check the status of the account:
```bash
sudo passwd -S audit2
```
*   `-S` (status) shows if the account password is locked (`L`), has no password (`NP`), or is usable (`P`).

---

## Part 5: Force shortterm3 to expire in 14 days

We want the actual user account to expire automatically in 14 days. This is different from forcing a password change.
```bash
sudo chage -E "$(date -d '+14 days' +%Y-%m-%d)" shortterm3
```
*   `chage -E`: Sets the absolute account expiration date. Once this date passes, the user cannot log in at all, even with SSH keys or API keys.
*   `$(date -d '+14 days' +%Y-%m-%d)`: This dynamically calculates the date 14 days from now in the required `YYYY-MM-DD` format.

Verify the change:
```bash
sudo chage -l shortterm3
```
*   `-l`: Lists the current password aging and account expiration details.

---

## Part 6: Remove leaver5

```bash
sudo userdel -r leaver5
```
*   `userdel -r`: The `-r` (remove) flag tells the system to delete the user account from `/etc/passwd` AND completely wipe out their home directory and mail spool. Without `-r`, the home directory would remain on disk as orphaned files.

---

## Verification

Run these commands to verify your work before running the validation scripts:

```bash
# Verify analyst9 relocation
id analyst9                     # Primary group should be finance
getent passwd analyst9          # Should show home directory as /home/accounts/analyst9
ls -l /home/accounts/analyst9   # Confirm original files are present and readable

# Verify newhire9 setup
id newhire9                     # Should show groups finance, ops, billing-team
sudo -l -U newhire9             # Confirm the exact NOPASSWD command allowed
su - newhire9 -c "sudo -n bash /root/rotate-logs.sh" # Test the sudo rule (should succeed without prompt)

# Verify groups
getent group billing-team       # Confirm GID is 6000, members are analyst9 and newhire9
getent group archive-billing    # Confirm GID is 7000 and legacy-billing name is gone
getent group temp-scratch       # Confirm no output (deleted)

# Verify lock and expiry states
sudo passwd -S audit2           # Should show "L" (locked)
sudo chage -l shortterm3        # Confirm account expiration date is set to 14 days from now

# Verify deletion
id leaver5                      # Confirm "no such user"
ls -la /home/leaver5            # Confirm "No such file or directory"
```
