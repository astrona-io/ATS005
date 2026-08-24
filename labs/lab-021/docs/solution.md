# Solution Walkthrough

Follow these steps to grant scoped ACL access without touching group membership:

---

## Step 1: Inspect the current state

```bash
ls -ld /srv/projects/orion
getfacl /srv/projects/orion
```

Confirm the baseline: owner `team-lead`, group `orion-team`, mode `750`, and no trailing `+` yet — meaning no ACL is present.

---

## Step 2: Grant contractor-jane read-write access, recursively

```bash
sudo setfacl -R -m u:contractor-jane:rwx /srv/projects/orion
```

`-R` ensures every file and subdirectory already inside the tree gets the same entry, not just the top-level directory. `rwx` (not `rw-`) is required on directories so contractor-jane can actually traverse into subdirectories.

---

## Step 3: Grant auditor-tom read-only access, recursively

```bash
sudo setfacl -R -m u:auditor-tom:rx /srv/projects/orion
```

`rx` allows listing/reading and traversal, but no writes.

---

## Step 4: Set default ACLs so future files inherit automatically

```bash
sudo setfacl -d -m u:contractor-jane:rwx /srv/projects/orion
sudo setfacl -d -m u:auditor-tom:rx /srv/projects/orion
```

Steps 2–3 only cover what already exists; this step is what makes every *future* file/subdirectory created under `/srv/projects/orion` automatically pick up both entries at creation time.

---

## Step 5: Verify ownership and mode are unchanged

```bash
ls -ld /srv/projects/orion
```

Expected: `drwxr-x---+ ... team-lead orion-team ...` — the trailing `+` is new, but owner, group, and the base mode digits are untouched.

---

## Step 6: Verify the full ACL state

```bash
getfacl /srv/projects/orion
```

Expected (abbreviated):

```text
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

## Step 7: Prove inheritance with a live test

```bash
sudo -u contractor-jane touch /srv/projects/orion/test-write.txt
sudo -u auditor-tom cat /srv/projects/orion/test-write.txt
getfacl /srv/projects/orion/test-write.txt
```

The last command should already show both named-user entries on the brand-new file, even though `setfacl` was never run against it directly — proof the default ACL inheritance from Step 4 works.

Once verified, run the local validation suite to pass the lab!
