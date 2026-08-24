# Solution Walkthrough

This guide explains how to configure granular Access Control Lists (ACLs) for users outside a primary group, find current session limits, set up proper PAM-enforced system boundaries, and restrict maximum group logins.

---

## Part 1: Scoped ACL access on /srv/data/atlas

Standard Linux permission modes (owner, group, other) only allow you to define access for a single owner, a single group, and everyone else. When you need to grant specific permissions to multiple users who are not in the primary group, you use Access Control Lists (ACLs).

### Step 1: Inspect the baseline permissions
Before changing anything, inspect the current ownership, permissions, and ACL status of the directory:
```bash
ls -ld /srv/data/atlas
getfacl /srv/data/atlas
```
*   `ls -ld`: Shows directory details rather than listing its contents. Note that the permission block (e.g. `drwxr-x---`) ends with a standard dot or space, indicating no ACL is active yet.
*   `getfacl`: Displays the active file access control list. Currently, it should map exactly to standard user/group/other file modes.

### Step 2: Grant vendor-lee read-write access
We want `vendor-lee` to have read, write, and execute permissions on `/srv/data/atlas` and everything already inside it.
```bash
sudo setfacl -R -m u:vendor-lee:rwx /srv/data/atlas
```
*   `setfacl`: The utility to modify ACLs.
*   `-R`: The **recursive** flag. This ensures that the permission is applied to `/srv/data/atlas` and all files and subdirectories already existing inside it.
*   `-m`: The **modify** flag, used to add or update an ACL entry.
*   `u:vendor-lee:rwx`: Defines the subject as a user (`u`), names the user (`vendor-lee`), and sets the level of access (`rwx`).
*   **Why `x` (execute) is required on directories:** In Linux, you must have execute permissions on a directory to pass through it or list its contents. If you only gave `rw-`, `vendor-lee` would not be able to navigate into the directory!

### Step 3: Grant qa-nina read-only access
We want `qa-nina` to have read and execute permissions recursively on the current folder tree.
```bash
sudo setfacl -R -m u:qa-nina:rx /srv/data/atlas
```
*   `u:qa-nina:rx`: Grants read and traverse access without allowing files to be written or modified.

### Step 4: Configure automatic default inheritance
Steps 2 and 3 apply to files that *already exist*. If a user creates a new file tomorrow, standard ACLs will not apply to it. To fix this, we must set **default ACLs** on the parent directory.
```bash
sudo setfacl -d -m u:vendor-lee:rwx /srv/data/atlas
sudo setfacl -d -m u:qa-nina:rx /srv/data/atlas
```
*   `-d`: The **default** flag. It tells the kernel: "When any user creates a new file or directory inside `/srv/data/atlas`, copy these exact ACLs onto that new item automatically at creation time."

### Step 5: Verify the ACL changes
```bash
ls -ld /srv/data/atlas
```
*   **What to look for:** You should see a trailing `+` character at the end of the permission block (e.g., `drwxr-x---+`). The `+` sign is the kernel's way of telling you that extended ACL permissions are active on this directory.

View the full list of active and default rules:
```bash
getfacl /srv/data/atlas
```

---

## Part 2: Proper hard nproc limit for derek

A previous admin attempted to enforce a process limit (`nproc`) on user `derek` by adding a line in their personal `.bashrc` profile. This is bad practice:
1.  `.bashrc` is only executed for interactive bash shells. Non-interactive or other shell sessions bypass it.
2.  It set only a **soft** limit. Soft limits are advisory and can be raised by the user at will. We want to configure a PAM-enforced **hard** limit (which only root can increase).

### Step 1: Discover derek's current soft limit value
Inspect derek's `.bashrc` file to find where the `ulimit` was written:
```bash
sudo grep -n ulimit /home/derek/.bashrc
```
Let's query the system directly to find the exact numerical soft limit currently applied to derek's environment:
```bash
sudo -u derek -i ulimit -Sp
```
*   `sudo -u derek -i`: Opens an interactive login session as `derek`, ensuring `.bashrc` is fully sourced.
*   `ulimit -Sp`: Displays the active **soft** (`-S`) process limit (`-p` / `nproc`). Note down this number (for example, `150`).

### Step 2: Enforce the hard limit via PAM
Rather than modifying `/etc/security/limits.conf` directly, we will write a custom configuration inside `/etc/security/limits.d/`. This keeps our customizations modular and isolated.

Create and open the limit configuration file:
```bash
sudo vi /etc/security/limits.d/derek-nproc.conf
```
Add the following line (replace `<value-from-step-1>` with the actual number you found, like `150`):
```text
derek hard nproc <value-from-step-1>
```
Let's break down this syntax:
*   `derek`: The target user account.
*   `hard`: Sets a hard limit that cannot be bypassed by the user.
*   `nproc`: Specifies the maximum number of processes the user can run.

### Step 3: Remove the old .bashrc hack
Since PAM now handles limits securely at session startup, remove the old line from derek's `.bashrc` file to clean up:
```bash
sudo sed -i '/ulimit -Sp/d' /home/derek/.bashrc
```
*   `sed -i '/pattern/d'`: Searches for the line containing `ulimit -Sp` and deletes (`d`) it in-place (`-i`).

---

## Part 3: supportstaff maxlogins

We want to restrict every individual member of the `supportstaff` group to a maximum of `1` active login session at any time.

### Step 1: Verify the group exists
```bash
getent group supportstaff
```

### Step 2: Write the limit rule
Create a dedicated configuration drop-in file:
```bash
sudo vi /etc/security/limits.d/supportstaff-maxlogins.conf
```
Add the following rule:
```text
@supportstaff hard maxlogins 1
```
Let's break down this syntax:
*   `@supportstaff`: The `@` symbol tells PAM that the target is a **group** instead of a single user account.
*   `hard`: Enforces a strict, unbypassable hard ceiling.
*   `maxlogins`: Restricts the maximum number of concurrent login sessions.

---

## Verification

Confirm your configurations are correct before concluding the lab:

```bash
# Test ACL access permissions
getfacl /srv/data/atlas

# Test ACL default inheritance by creating a test file as vendor-lee
sudo -u vendor-lee touch /srv/data/atlas/probe.txt
getfacl /srv/data/atlas/probe.txt   # Verify both users are automatically listed in the output
sudo rm /srv/data/atlas/probe.txt

# Verify derek's process limit configurations
sudo grep nproc /etc/security/limits.d/derek-nproc.conf
sudo grep ulimit /home/derek/.bashrc   # Expect no output (confirming deletion)

# Verify supportstaff maxlogins rule is defined
sudo grep maxlogins /etc/security/limits.d/supportstaff-maxlogins.conf
```
