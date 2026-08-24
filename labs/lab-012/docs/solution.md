# Solution Walkthrough

## Step 1: Create the new group with an exact GID

```bash
sudo groupadd -g 5000 datateam
getent group datateam
```

`-g` pins the exact GID. Without it, `datateam` would get whatever GID happens to be next free.

## Step 2: Add marta and cilla as supplementary members

```bash
sudo usermod -aG datateam marta
sudo usermod -aG datateam cilla
```

`-aG` (append) preserves each user's existing primary group and any other supplementary groups. Plain `-G` would replace the entire list, wiping out everything else they belonged to.

## Step 3: Confirm membership (in a fresh session)

```bash
id marta
```

If checked in a shell that predates Step 2, this may still show the old group list. Confirm properly with a fresh login/SSH session, or:

```bash
sudo -u marta newgrp datateam
```

## Step 4: Rename legacy-ops without touching its GID or members

```bash
getent group legacy-ops
sudo groupmod -n platform-ops legacy-ops
getent group platform-ops
```

`-n` renames only — the GID and the member list in `/etc/group` are untouched.

## Step 5: Delete the unused group

```bash
getent group temp-audit
sudo find / -xdev -gid "$(getent group temp-audit | cut -d: -f3)" 2>/dev/null
sudo groupdel temp-audit
```

Confirm no files still reference the GID before deleting — `groupdel` does not search the filesystem or reassign orphaned ownership.

## Verification

```bash
getent group datateam
# expect: datateam:x:5000:marta,cilla

id marta
id cilla
# expect: both list datateam (in a fresh session or after newgrp)

getent group platform-ops
# expect: GID 4200, membership list intact

getent group legacy-ops
# expect: no output

getent group temp-audit
# expect: no output
```

## Command Summary

```bash
sudo groupadd -g 5000 datateam
sudo usermod -aG datateam marta
sudo usermod -aG datateam cilla

getent group legacy-ops
sudo groupmod -n platform-ops legacy-ops

sudo groupdel temp-audit

getent group datateam
getent group platform-ops
getent group temp-audit
```
