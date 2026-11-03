# Solution Walkthrough

This walkthrough uses access control lists (ACLs) to give two outside users their own access to the Orion tree, without changing the team, the owner or the base permissions. An ACL is a guest list taped to a file or directory: each named entry gives one more user its own permissions. Run every command on the lab machine (`astrona ssh ats-005-lab-021`).

---

## Step 1: Look at the directory as it is now

Before you change anything, look at the owner, the group and the current access:

```bash
ls -ld /srv/projects/orion
getfacl /srv/projects/orion
```

- `ls -ld` shows the directory itself, not its contents. The permission string (for example `drwxr-x---`) has no `+` at the end yet, so no ACL is set.
- `getfacl` prints the full access list. Right now it only repeats the standard owner, group and other permissions.

---

## Step 2: Give contractor-jane read-write access

Give `contractor-jane` read (`r`), write (`w`) and pass-through (`x`) on the whole existing tree:

```bash
sudo setfacl -R -m u:contractor-jane:rwx /srv/projects/orion
```

- `setfacl` is the tool that sets ACL entries.
- `-R` (recursive) applies the entry to `/srv/projects/orion` and every file and subdirectory already inside it.
- `-m` (modify) adds or updates an entry.
- `u:contractor-jane:rwx` means: a user (`u`), named `contractor-jane`, with `rwx`.
- **Why `x` on directories:** a user needs execute permission on a directory to enter it or reach the files inside. With only `rw-`, `contractor-jane` could not get into the subdirectories.

---

## Step 3: Give auditor-tom read-only access

Give `auditor-tom` read and pass-through on the same tree, without write:

```bash
sudo setfacl -R -m u:auditor-tom:rx /srv/projects/orion
```

- `u:auditor-tom:rx` grants read and pass-through. Without `w`, the user cannot change files or create new ones.

---

## Step 4: Make new files inherit both entries

Steps 2 and 3 only cover files that *already exist*. A file someone creates tomorrow would not get the entries. **Default ACLs** on the directory fix that:

```bash
sudo setfacl -d -m u:contractor-jane:rwx /srv/projects/orion
sudo setfacl -d -m u:auditor-tom:rx /srv/projects/orion
```

- `-d` (default) sets a default entry. Whenever anyone creates a file or directory inside `/srv/projects/orion`, the kernel copies these entries onto the new item at the moment it is created.

---

## Step 5: Check that the standard permissions are intact

Look at the directory again:

```bash
ls -ld /srv/projects/orion
```

You should now see a `+` at the end of the permission string (for example `drwxrwx---+`). The `+` tells you that extended ACL entries are set. On a file with an ACL, the middle three letters show the ACL mask, not the group's own bits, which is why they can read `rwx` here; `getfacl` still shows `group::r-x`. The owner `team-lead` and the group `orion-team` are unchanged.

---

## Step 6: Check the full list of entries

Read every access and default entry:

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

The `user:` lines are the access entries. The `default:` lines are the template for new files.

---

## Step 7: Test inheritance live

Create a test file as `contractor-jane` and read its ACL:

```bash
# Create a test file as contractor-jane
sudo -u contractor-jane touch /srv/projects/orion/test-write.txt

# Inspect the file's ACLs
getfacl /srv/projects/orion/test-write.txt
```

The new file `test-write.txt` should already list both `contractor-jane` and `auditor-tom`, although you never ran `setfacl` on it.

Remove the test file:

```bash
sudo rm /srv/projects/orion/test-write.txt
```

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-021
```
