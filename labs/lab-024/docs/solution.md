# Solution Walkthrough

This walkthrough saves the ACLs of a tree, survives a cleanup accident, restores the lists and removes one user. Run every command on the lab machine (`astrona ssh ats-005-lab-024`).

---

## Step 1: Look at the tree

Print the named and default entries of the whole tree:

```bash
getfacl -R -p /srv/data/ledger | grep -E '^(# file|user:[a-z]|default:user)'
```

- You see `auditor-ivy` and `temp-vendor` on every path, defaults on folders, and `ledger-clerk` on `2025/q1.csv`.

---

## Step 2: Save the backup before anything else

```bash
sudo sh -c 'getfacl -R -p /srv/data/ledger > /root/ledger-acl.backup'
```

- `-R` walks the tree and `-p` keeps the leading `/`.
- The redirect runs inside `sh -c` so that `root` writes the file.

---

## Step 3: Run the cleanup

```bash
sudo /root/strip-acls.sh
getfacl -R -p /srv/data/ledger | grep -c 'user:auditor-ivy'
```

- The count is `0`. Every extended entry is gone.

---

## Step 4: Restore from the backup

```bash
sudo setfacl --restore=/root/ledger-acl.backup
```

- Run it as `root`, because it also sets owner and group from the comment lines.
- Check that `ledger-clerk` is back on `2025/q1.csv`.

---

## Step 5: Remove temp-vendor everywhere

```bash
sudo setfacl -R -x u:temp-vendor /srv/data/ledger
sudo find /srv/data/ledger -type d -exec setfacl -x d:u:temp-vendor {} +
getfacl -R -p /srv/data/ledger | grep -c temp-vendor
```

- The first command removes the access entries. The second removes the default entries, which `-x u:` does not touch.
- The count must be `0`. In this lab `temp-vendor` has no default entries, so the second command is a safe check. It keeps the habit that matters on a real ship.

---

## Step 6: Submit

```bash
astrona submit -c labs/lab-024
```
