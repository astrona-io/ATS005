# Solution Walkthrough

This guide explains how to manage group lifecycles, assign custom Group IDs (GIDs), and safely modify and clean up groups on a Linux system.

---

## Step 1: Create the datateam group with an exact GID

By default, Linux assigns the next available GID. However, we want to specify GID `5000` to maintain consistency across our organization.

```bash
sudo groupadd -g 5000 datateam
```
*   `-g 5000`: This flag specifies the exact GID for the new group.

Verify that the group has been created and has the correct GID:
```bash
getent group datateam
```
*   `getent`: This command retrieves entries from administrative databases. `getent group datateam` queries `/etc/group` and displays the entry for `datateam` in the format `group_name:password:GID:user_list`.

---

## Step 2: Add marta and cilla to the new group

We need to add both `marta` and `cilla` to `datateam` as a supplementary group without disturbing their current group assignments.

```bash
sudo usermod -aG datateam marta
sudo usermod -aG datateam cilla
```
Let's break down these flags:
*   `-aG`: The `-a` (append) flag is **critical** when combined with the `-G` (groups) flag on existing users. It adds the new group to the user's supplementary list while preserving all other groups they currently belong to.
*   **Warning:** If you run `usermod -G` without the `-a` flag on an existing user, it will replace their entire list of supplementary groups with *only* the group you specified, instantly stripping away their existing group memberships (such as `sudo` or `wheel` access)! Always use `-aG`.

---

## Step 3: Confirm group membership

You can check a user's current group memberships using the `id` command:

```bash
id marta
```
*   **Note on Session Expiry:** If you are running `id` inside an already-active shell session for `marta`, the system won't reflect the new group membership yet. Linux reads group memberships at session login time and caches them. To apply group changes immediately without logging out and back in, you can run:
    ```bash
    sudo -u marta newgrp datateam
    ```
    `newgrp` changes the current real group ID of the user's session dynamically.

---

## Step 4: Rename the legacy-ops group

We want to rename the group `legacy-ops` to `platform-ops` without altering its GID (`4200`) or its member list.

```bash
sudo groupmod -n platform-ops legacy-ops
```
*   `groupmod -n`: The `-n` (new name) flag updates the name of the group. The GID and the list of user members stored in `/etc/group` remain completely unchanged. This ensures that any files on the filesystem owned by GID `4200` continue to resolve correctly under the new name.

Verify that the renamed group exists with GID `4200`:
```bash
getent group platform-ops
```

---

## Step 5: Delete the unused group

We want to remove the group `temp-audit` from the system entirely.

```bash
sudo groupdel temp-audit
```
*   `groupdel` removes the group entry from `/etc/group`.
*   **Best Practice:** Before deleting a group, it is highly recommended to search the filesystem to ensure no files are still owned by that group's GID:
    ```bash
    sudo find / -xdev -gid "$(getent group temp-audit | cut -d: -f3)" 2>/dev/null
    ```
    If files still belong to that group, deleting the group will cause those files to display a raw number as their group owner (e.g. `4200` instead of a name), which can lead to orphaned permissions.

---

## Verification

Run these commands to verify that all requirements have been met:

```bash
# Verify group creation and GID
getent group datateam
# Expect: datateam:x:5000:marta,cilla

# Verify memberships
id marta
id cilla
# Expect: both list datateam as a supplementary group

# Verify renamed group GID and name
getent group platform-ops
# Expect: GID is 4200 and legacy-ops name is gone
getent group legacy-ops
# Expect: no output

# Verify group deletion
getent group temp-audit
# Expect: no output
```
