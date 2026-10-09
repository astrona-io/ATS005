# Solution Walkthrough

This walkthrough gives two outside users their own access to the Atlas tree with access control lists (ACLs), turns `derek`'s `.bashrc` limit into a hard limit that PAM (Pluggable Authentication Modules, the checklist every login passes through) enforces, and caps the `supportstaff` group to one login each. Run every command on the lab machine (`astrona ssh ats-005-lab-020`).

---

## Part 1: Scoped ACL access on /srv/data/atlas

Standard Linux permissions only describe one owner, one group and everyone else. When several users outside the group each need their own access, you use ACLs: a guest list taped to the directory, with one named entry per extra user.

### Step 1: Inspect the baseline permissions
Before you change anything, look at the owner, the permissions and the ACL of the directory:
```bash
ls -ld /srv/data/atlas
getfacl /srv/data/atlas
```
*   `ls -ld` shows the directory itself, not its contents. The permission string (for example `drwxr-x---`) has no `+` at the end yet, so no ACL is set.
*   `getfacl` prints the full access list. Right now it only repeats the standard owner, group and other permissions.

### Step 2: Grant vendor-lee read-write access
Give `vendor-lee` read, write and pass-through (execute) on `/srv/data/atlas` and everything already inside it:
```bash
sudo setfacl -R -m u:vendor-lee:rwx /srv/data/atlas
```
*   `setfacl` is the tool that sets ACL entries.
*   `-R` (recursive) applies the entry to `/srv/data/atlas` and every file and subdirectory already inside it.
*   `-m` (modify) adds or updates an entry.
*   `u:vendor-lee:rwx` means: a user (`u`), named `vendor-lee`, with `rwx`.
*   **Why `x` on directories:** a user needs execute permission on a directory to enter it or reach the files inside. With only `rw-`, `vendor-lee` could not get into the directory.

### Step 3: Grant qa-nina read-only access
Give `qa-nina` read and pass-through on the whole existing tree, without write:
```bash
sudo setfacl -R -m u:qa-nina:rx /srv/data/atlas
```
*   `u:qa-nina:rx` grants read and pass-through. Without `w`, she cannot change files or create new ones.

### Step 4: Configure automatic default inheritance
Steps 2 and 3 only cover files that *already exist*. A file someone creates tomorrow would not get the entries. **Default ACLs** on the directory fix that:
```bash
sudo setfacl -d -m u:vendor-lee:rwx /srv/data/atlas
sudo setfacl -d -m u:qa-nina:rx /srv/data/atlas
```
*   `-d` (default) sets a default entry. Whenever anyone creates a file or directory inside `/srv/data/atlas`, the kernel copies these entries onto the new item at the moment it is created.

### Step 5: Verify the ACL changes
```bash
ls -ld /srv/data/atlas
```
*   **What to look for:** a `+` at the end of the permission string (for example `drwxrwx---+`). The `+` tells you that extended ACL entries are set. With an ACL, the middle three letters show the ACL mask, not the group's own bits.

Read every access and default entry:
```bash
getfacl /srv/data/atlas
```

---

## Part 2: Proper hard nproc limit for derek

A previous administrator tried to limit the number of processes (`nproc`) for `derek` with a line in his personal `.bashrc`. That is a weak fix, for two reasons:
1.  `.bashrc` only runs for interactive bash shells. Non-interactive sessions skip it.
2.  It sets only a **soft** limit, which the user can raise whenever he likes. You want a **hard** limit, enforced by PAM, that only `root` can raise.

### Step 1: Discover derek's current soft limit value
Look at the line in derek's `.bashrc`:
```bash
sudo grep -n ulimit /home/derek/.bashrc
```
The number at the end of the `ulimit -Sp` line (for example, `120`) is the value the task asks you to keep, and the grader compares your hard limit with it.

You may also see this check, which reads the value from a login shell:
```bash
sudo -u derek -i ulimit -Sp
```
*   `sudo -u derek -i` opens an interactive login shell as `derek`, so his `.bashrc` is read.
*   `ulimit -Sp` asks for a **soft** (`-S`) value.

Be careful with this one. In bash, the `-p` option of `ulimit` is the pipe size, not the process limit; the process limit is `-u` (`ulimit -Su`). So this command does not print the process limit, and the planted `ulimit -Sp` line never set one. Take the number from the `.bashrc` line itself.

### Step 2: Enforce the hard limit via PAM
Do not edit the big `/etc/security/limits.conf` file. Write your own drop-in file in `/etc/security/limits.d/`, which keeps the change separate and easy to review.

Create and open the drop-in file:
```bash
sudo vi /etc/security/limits.d/derek-nproc.conf
```
Add this line (replace `<value-from-step-1>` with the number you found in Step 1):
```text
derek hard nproc <value-from-step-1>
```
Here is what each column means:
*   `derek`: the user the line applies to.
*   `hard`: a hard limit, which the user cannot raise.
*   `nproc`: the maximum number of processes the user may run at once.

### Step 3: Remove the old .bashrc hack
PAM now applies the limit at every session start, so remove the old line from derek's `.bashrc`:
```bash
sudo sed -i '/ulimit -Sp/d' /home/derek/.bashrc
```
*   `sed -i '/pattern/d'` finds every line that contains `ulimit -Sp` and deletes (`d`) it in place (`-i`).

---

## Part 3: supportstaff maxlogins

Every member of `supportstaff` may have at most `1` login session at a time. The limit is read by the PAM module `pam_limits.so`, which Ubuntu switches on out of the box (`grep -n pam_limits /etc/pam.d/common-session` shows its line).

### Step 1: Verify the group exists
```bash
getent group supportstaff
```

### Step 2: Write the limit rule
Create a separate drop-in file:
```bash
sudo vi /etc/security/limits.d/supportstaff-maxlogins.conf
```
Add this line:
```text
@supportstaff hard maxlogins 1
```
Here is what each column means:
*   `@supportstaff`: the `@` tells PAM that the target is a **group**, not a single user.
*   `hard`: a hard ceiling the members cannot raise.
*   `maxlogins`: the maximum number of login sessions open at the same time.

---

## Check your work

Check every change before you send the lab for grading:

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

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-020
```
