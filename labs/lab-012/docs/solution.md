# Solution Walkthrough

This walkthrough creates a group with an exact GID, adds two members safely, renames a group without losing anything, and deletes an unused group. Run every command on the lab machine (`astrona ssh ats-005-lab-012`).

---

## Step 1: Create the datateam group with an exact GID

Without an option, `groupadd` takes the next free GID. The task asks for GID `5000`, so pin it:

```bash
sudo groupadd -g 5000 datateam
```

- `-g 5000` sets the exact GID for the new group.

Check that the group exists with the right GID:

```bash
getent group datateam
```

- `getent` reads entries from the system's account databases. `getent group datateam` prints the group's line in the form `group_name:password:GID:user_list`.

---

## Step 2: Add marta and cilla to the new group

Add both users to `datateam` as a supplementary group, without touching their other groups:

```bash
sudo usermod -aG datateam marta
sudo usermod -aG datateam cilla
```

- `-aG` is the important part. `-a` (append) together with `-G` (groups) adds the new group and keeps every group the user already has.
- **Warning:** `usermod -G` without `-a` on an existing user replaces their whole supplementary list with only the group you name. They would lose every other membership, such as `sudo`. Always use `-aG` here.

Neither command touches the primary group, so `marta` and `cilla` keep `staff`.

---

## Step 3: Confirm group membership

Check a user's groups with `id`:

```bash
id marta
```

- **A note on open sessions:** a shell that `marta` already had open does not show the new group yet. Linux reads group membership when a session starts and keeps that list. To see the change at once without logging out and in again, you can run:

  ```bash
  sudo -u marta newgrp datateam
  ```

  `newgrp` starts a subshell with `datateam` as its active group. Type `exit` to leave it.

---

## Step 4: Rename the legacy-ops group

Rename `legacy-ops` to `platform-ops` without changing its GID (`4200`) or its member list:

```bash
sudo groupmod -n platform-ops legacy-ops
```

- `groupmod -n` (new name) changes only the group's name. The GID and the list of members in `/etc/group` stay exactly as they were. Files owned by GID `4200` keep working under the new name, because Linux stores the number, not the name.

Check that the renamed group exists with GID `4200`:

```bash
getent group platform-ops
```

---

## Step 5: Delete the unused group

Before you delete a group, check that no files on disk are still owned by its GID:

```bash
sudo find / -xdev -gid "$(getent group temp-audit | cut -d: -f3)" 2>/dev/null
```

If files still belonged to the group, deleting it would leave them with a bare number as their group owner (for example `4200` instead of a name). No output means the delete is clean. Now remove the group:

```bash
sudo groupdel temp-audit
```

- `groupdel` removes the group's entry from `/etc/group`. It does not change any files.

---

## Step 6: Check your work and submit

Run these commands to check every requirement:

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

`id marta` and `id cilla` should still show `gid=` with `staff`.

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-012
```
