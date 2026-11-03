# Question

Solve this question on: `terminal`

Astronaut, the tree `/srv/data/ledger` carries guest lists for several people. The script `/root/strip-acls.sh` runs `setfacl -R -b` on it and wipes every list. The crew still needs the lists afterwards, so photograph them before you run it.

1. Save the ACLs of the whole tree, with absolute paths, to `/root/ledger-acl.backup`.
2. Run `/root/strip-acls.sh` once, as `root`.
3. Restore every ACL from the backup file.
4. Then remove every entry for `temp-vendor` from the whole tree, including the default entries on folders. All other entries must stay as they were before the cleanup.
5. Do not change owners, groups or the file modes.

The grader checks that the backup file holds the named, clerk and default entries, that `auditor-ivy` has `r-x` on folders and the script and `r--` on data files, that the default entries and the entry for `ledger-clerk` are back, that `temp-vendor` appears nowhere, and that the owners are unchanged.
