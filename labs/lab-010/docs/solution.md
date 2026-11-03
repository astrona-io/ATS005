# Solution Walkthrough

This walkthrough completes all six tasks of the sweep, one part at a time. For each command it explains what the options do, so you learn the tool and not just the line. Run every command on the lab machine (`astrona ssh ats-005-lab-010`).

---

## Part 1: Relocate analyst9

Change `analyst9`'s primary group to `finance`, move the home directory to `/home/accounts/analyst9`, and take the existing files along.

### Step 1: Create the parent directory and group
Before you move the user, make sure the parent directory and the `finance` group exist.
```bash
sudo groupadd -f finance
sudo mkdir -p /home/accounts
```
- `groupadd -f`: `-f` (force) makes `groupadd` succeed quietly if the group already exists.
- `mkdir -p`: `-p` (parents) creates `/home/accounts` and any missing directories above it, and does not complain if it already exists. `usermod -m` needs this parent, because it does not create it.

### Step 2: Relocate the user
Change the account with `usermod`:
```bash
sudo usermod -g finance -d /home/accounts/analyst9 -m analyst9
```
Here is what each option does:

- `-g finance` sets the user's **primary** group to `finance`. New files they create get this group.
- `-d /home/accounts/analyst9` sets the new home path in `/etc/passwd`.
- `-m` **moves** the files. `-d` alone only changes the path written in the account record. `-m` moves every file from the old home to the new path. Without it, the user would log in to an empty directory.

---

## Part 2: Provision newhire9 with scoped sudo

Add `newhire9` with the `finance` and `ops` groups, the right home and shell, and one exact `sudo` rule.

### Step 1: Create the ops group
```bash
sudo groupadd -f ops
```

### Step 2: Create the user
```bash
sudo useradd -m -d /home/accounts/newhire9 -G finance,ops -s /bin/bash newhire9
```
Here is what each option does:

- `-m` creates the home directory.
- `-d /home/accounts/newhire9` sets the exact home path.
- `-G finance,ops` (capital `G`) sets the **supplementary** groups. On a new account there is no old list to lose, so a comma-separated list is safe.
- `-s /bin/bash` sets `/bin/bash` as the login shell instead of the system default, which may be a basic shell such as `/bin/sh`.

### Step 3: Configure scoped sudo access
`newhire9` must run exactly one script as `root` with no password. First check where `bash` is installed on this machine:
```bash
which bash
```
Usually this is `/usr/bin/bash` or `/bin/bash`. Write the rule in its own file in `/etc/sudoers.d/`. A drop-in file is safer than editing the main `/etc/sudoers` file: each rule stays separate and is easy to remove.

Edit the file with `visudo`, which checks the syntax before it saves. That stops one typo from locking everyone out of `sudo`.
```bash
sudo visudo -f /etc/sudoers.d/newhire9-rotate-logs
```
Add this line exactly, with the path `which bash` reported:
```text
newhire9 ALL=(root) NOPASSWD: /usr/bin/bash /root/rotate-logs.sh
```
Here is what each piece means:

- `newhire9`: the user the rule applies to.
- `ALL=`: the rule applies on all hosts.
- `(root)`: the command runs as `root`.
- `NOPASSWD:`: `sudo` does not ask `newhire9` for a password for this command.
- `/usr/bin/bash /root/rotate-logs.sh`: the exact command allowed. Anything else, even a small variation, is refused.

Save and quit. Then set the permissions and owner. `sudo` ignores a rules file that others can write to, or that `root` does not own:
```bash
sudo chmod 0440 /etc/sudoers.d/newhire9-rotate-logs
sudo chown root:root /etc/sudoers.d/newhire9-rotate-logs
sudo visudo -c
```
- `chmod 0440`: read-only for the owner and the group, no access for anyone else.
- `visudo -c`: checks the main file and every drop-in for syntax errors.

---

## Part 3: Group lifecycle

### Step 1: Create a group with a specific GID
```bash
sudo groupadd -g 6000 billing-team
```
- `-g 6000` sets the exact group ID (GID) `6000`. Without it, `groupadd` takes the next free GID; a fixed number keeps file ownership consistent across machines.

### Step 2: Add users to the group
```bash
sudo usermod -aG billing-team analyst9
sudo usermod -aG billing-team newhire9
```
- `-aG`: on an existing user, always use `-a` (append) together with `-G` (groups). It adds the group to the supplementary list *without* removing any group the user already has. Without `-a`, `usermod` would replace every supplementary group with only `billing-team`. The primary group is not touched either way.

### Step 3: Rename an existing group
Rename `legacy-billing` to `archive-billing` without changing its GID (`7000`) or losing its members:
```bash
sudo groupmod -n archive-billing legacy-billing
```
- `groupmod -n`: `-n` (new name) changes only the group's name. The GID and the member list in `/etc/group` stay exactly as they were.

### Step 4: Delete an unused group
```bash
sudo groupdel temp-scratch
```
- `groupdel` removes the group from `/etc/group`. It does not change any files. Any file still owned by the group's GID would then show a bare number as its group instead of a name, so in real work check first with `find / -xdev -gid <GID>`.

---

## Part 4: Lock audit2

An account under investigation must stop logging in at once, but its files and settings must stay:
```bash
sudo passwd -l audit2
```
- `passwd -l`: `-l` (lock) puts a `!` in front of the password hash in `/etc/shadow`. The hash can no longer match, so nobody can log in with the password. The original hash stays, so `passwd -u` can unlock it later.

Check the status of the account:
```bash
sudo passwd -S audit2
```
- `-S` (status) shows whether the password is locked (`L`), missing (`NP`) or usable (`P`).

---

## Part 5: Force shortterm3 to expire in 14 days

The account itself must expire in 14 days. That is different from forcing a password change:
```bash
sudo chage -E "$(date -d '+14 days' +%Y-%m-%d)" shortterm3
```
- `chage -E` sets the account expiration date. After that date, the account cannot log in at all, whatever the password.
- `$(date -d '+14 days' +%Y-%m-%d)` works out the date 14 days from now in the `YYYY-MM-DD` format `chage` expects.

Check the change:
```bash
sudo chage -l shortterm3
```
- `-l` (list) shows the password and account dates.

---

## Part 6: Remove leaver5

```bash
sudo userdel -r leaver5
```
- `userdel -r`: `-r` (remove) deletes the account from `/etc/passwd` **and** its home directory and mail spool. Without `-r`, the home directory would stay on disk, owned by a UID with no name.

---

## Check your work and submit

Run these commands to check your work before you send the lab for grading:

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

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-010
```
