# Solution Walkthrough

This guide explains how to use Access Control Lists (ACLs) to grant precise, granular file permissions to specific users without altering their primary group memberships or changing traditional Unix file permissions.

---

## Step 1: Inspect the current state of the directory

Before modifying permissions, inspect the directory to see its current owner, group, and standard file modes:

```bash
ls -ld /srv/projects/orion
getfacl /srv/projects/orion
```
*   `ls -ld`: Displays information about the `/srv/projects/orion` directory itself. You should see standard permissions (e.g. `drwxr-x---`) ending with a blank space or dot, which indicates that no ACLs are currently configured.
*   `getfacl`: Displays the active file access control list. It currently mirrors standard Unix owner, group, and other file permissions.

---

## Step 2: Grant contractor-jane read-write access

We want to grant `contractor-jane` read (`r`), write (`w`), and directory traversal (`x`) permissions to the entire existing folder structure.

```bash
sudo setfacl -R -m u:contractor-jane:rwx /srv/projects/orion
```
Let's break down this command:
*   `setfacl`: The tool used to configure Access Control Lists.
*   `-R`: The **recursive** flag. This ensures the permission is applied to `/srv/projects/orion` and every existing file and subdirectory inside it.
*   `-m`: The **modify** flag, indicating we are adding or updating a rule.
*   `u:contractor-jane:rwx`: Defines the subject type as a user (`u`), specifies the username (`contractor-jane`), and sets their access levels (`rwx`).
*   **Why we grant `x` (execute) on folders:** In Linux, users must have execute permissions on a directory to enter (traverse) it or list its contents. If you only give `rw-`, `contractor-jane` will be completely locked out of traversing into subfolders!

---

## Step 3: Grant auditor-tom read-only access

We want to grant `auditor-tom` read (`r`) and traverse (`x`) access across the existing folder tree without letting them edit files.

```bash
sudo setfacl -R -m u:auditor-tom:rx /srv/projects/orion
```
*   `u:auditor-tom:rx`: Grants read and traversal access. Since the `w` (write) flag is omitted, the user cannot modify any files or write new ones.

---

## Step 4: Configure automatic default inheritance

Steps 2 and 3 apply only to files that *already exist*. If a team member creates a new file tomorrow, standard ACLs will not apply to it. To make permissions persistent, we configure **default ACLs** on the parent directory.

```bash
sudo setfacl -d -m u:contractor-jane:rwx /srv/projects/orion
sudo setfacl -d -m u:auditor-tom:rx /srv/projects/orion
```
*   `-d`: The **default** flag. It instructs the kernel: "Whenever any user creates a new file or directory inside `/srv/projects/orion`, automatically copy these exact ACL settings onto that new item at the moment of creation."

---

## Step 5: Verify standard permissions are intact

Inspect the directory permissions block once again:
```bash
ls -ld /srv/projects/orion
```
*   **What to look for:** You should see a trailing `+` character at the end of the permission block (e.g. `drwxr-x---+`). The `+` sign is the kernel's way of telling you that extended ACL permissions are active on this directory.

---

## Step 6: Verify the full ACL rule list

Verify that all active and default rules have been written correctly:

```bash
getfacl /srv/projects/orion
```
Expected output:
```text
# file: srv/projects/orion
# owner: team-lead
# group: orion-team
user::rwx
user:contractor-jane:rwx
user:auditor-tom:r-x
group::r-x
mask::rwx
other::---
default:user::rwx
default:user:contractor-jane:rwx
default:user:auditor-tom:r-x
default:group::r-x
default:mask::rwx
default:other::---
```

---

## Step 7: Test permission inheritance live

You can verify that inheritance is working perfectly by creating a file as an administrator and checking its permissions:

```bash
# Create a test file as contractor-jane
sudo -u contractor-jane touch /srv/projects/orion/test-write.txt

# Inspect the file's ACLs
getfacl /srv/projects/orion/test-write.txt
```
*   **What to look for:** The newly created file `test-write.txt` should automatically contain ACL entries for both `contractor-jane` and `auditor-tom` without you ever having to run `setfacl` on it directly!

Clean up the test file:
```bash
sudo rm /srv/projects/orion/test-write.txt
```
Once verified, run the local validation suite to pass the lab!
