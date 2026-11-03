# Backup And Restore

Astronaut, a guest list lives on the crate itself. Copy the crate with the wrong tool, or clean the hold in a hurry, and the guest list is gone. This part shows you how to photograph every list into a plain text file and how to put them all back with one command.

## Photograph the guest lists

`getfacl -R -p` prints the ACLs of a tree in a form that `setfacl` can read back. Redirect the output into a file and you have a backup. The `-p` keeps the full path, so the restore finds each crate wherever you run it from.

### Save a backup

Save the whole ledger tree's ACLs to a file in `root`'s home:

<!-- astrona:playground:renew -->

```sh
sudo sh -c 'getfacl -R -p /srv/data/ledger > /root/ledger-acl.backup'
sudo grep -c '^# file:' /root/ledger-acl.backup
sudo grep -E '^# (owner|group)' /root/ledger-acl.backup | head -n 2
```

Expect a number that matches the count of folders and files in the tree, followed by an owner line and a group line. The file records each path, its owner and group, and every entry, including the `default:` lines. The redirect runs inside `sh -c` so that `root`, not you, writes the file.

## Lose the lists, then bring them back

Now run the careless cleanup, check the damage, and restore.

### Strip every ACL

The playground has a script that runs `setfacl -R -b` on the tree. Run it, then look:

```sh
sudo /root/strip-acls.sh
getfacl -R -p /srv/data/ledger | grep -c 'user:auditor-ivy'
```

Expect `0`. Every extended entry is gone. Without the backup you would have to remember every name, every letter and the one odd entry on one file.

### Restore from the backup

`setfacl --restore=<file>` reads a backup made by `getfacl -R` and puts every entry back. It also restores the owner and group named in the comment lines, so run it as `root`. It cannot be mixed with other options.

```sh
sudo setfacl --restore=/root/ledger-acl.backup
getfacl -R -p /srv/data/ledger | grep -E '^user:[a-z]' | sort | uniq -c
```

The count line for each named user is back, including `ledger-clerk` on its single file, which nobody had to remember. Run the first `getfacl` command from the last part again if you want to see the whole picture.

## What the backup does not cover

The backup holds ACLs, owners and the setuid, setgid and sticky flags. It does not hold file contents. Do not call it a replacement for a file backup. To keep ACLs inside a file backup, use a tool that stores extended attributes, such as `tar --acls`.

## Common pitfalls

> [!WARNING]
> - **Leaving out `-p`.** The paths in the backup lose the leading `/`, and a restore from a different folder misses the files. Always save with `-R -p`.
> - **Using `>` with `sudo` directly.** The redirect runs as you, not as `root`, and fails with "Permission denied". Wrap it in `sudo sh -c '...'`.
> - **Taking the backup after the cleanup.** An empty backup restores nothing. Save first, then change.
> - **Restoring as a normal user.** Owners and groups cannot be set, and the restore stops. Use `sudo`.

## Your mission: ACL Tree Backup And Restore Lab

You can now read, change and remove ACLs on a whole tree, and you can save them and bring them back. The mission asks for the full cycle: a backup, a cleanup accident, a restore and one removal.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop acl-backup-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-024
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-024
```

Read the task in [`question.md`](../../../labs/lab-024/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-024
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-024
astrona start acl-backup-playground
```
