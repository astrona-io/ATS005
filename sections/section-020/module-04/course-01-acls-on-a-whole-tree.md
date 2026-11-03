# ACLs On A Whole Tree

Astronaut, a cargo hold has compartments inside compartments. This part shows you how to read every guest list in the hold with one command, how to hand out access to the whole hold at once, and how to take one name off every list or wipe all lists.

## Read every guest list at once

`getfacl` prints the ACL of the paths you name. With `-R` (recursive) it walks the whole tree. `-p` (absolute names) keeps the leading `/` in the path, which matters later for the restore.

### See the tree in your playground

Print the guest lists of the whole ledger tree, and keep only the path lines and the named user lines:

<!-- astrona:playground:renew -->

```sh
getfacl -R -p /srv/data/ledger | grep -E '^(# file|user:[a-z])'
```

Expect something like this (shortened):

```text
# file: /srv/data/ledger
user:auditor-ivy:r-x
user:temp-vendor:r-x
# file: /srv/data/ledger/2024
user:auditor-ivy:r-x
...
```

Every folder and file in the tree has its own list. The two named users appear on every path. One file also lists `ledger-clerk`, as you will see in a moment.

## Hand out access to the whole tree

You know `setfacl -R -m u:<user>:<perms>`. For a tree that holds both folders and files, the permission letters need care: a folder needs `x` so people can walk through it, but a plain data file should not become a program.

### The capital X

A capital `X` means "execute only if this is a folder, or already executable by someone". With `rX`, folders get `r-x`, programs keep `r-x` and plain files get just `r--`.

```sh
sudo setfacl -R -m u:auditor-ivy:rX /srv/data/ledger
getfacl -p /srv/data/ledger/2024/summary.txt /srv/data/ledger/tools/run-report.sh | grep -E '^(# file|user:auditor)'
```

Expect something like:

```text
# file: /srv/data/ledger/2024/summary.txt
user:auditor-ivy:r--
# file: /srv/data/ledger/tools/run-report.sh
user:auditor-ivy:r-x
```

The data file gets `r--` and the script gets `r-x`, from one command. A plain `rx` would have made every data file executable for `auditor-ivy`.

## Take names off

Two options remove entries. `-x` removes the entry of one named user or group. `-b` removes every extended entry and leaves only the owner, group and other bits.

### Remove one name from the whole tree

Take `temp-vendor` off every list, and check that nobody is left:

```sh
sudo setfacl -R -x u:temp-vendor /srv/data/ledger
getfacl -R -p /srv/data/ledger | grep -c temp-vendor
```

Expect `0`. The `-x` form takes the user and no permission letters. The other entries, such as the ones for `auditor-ivy`, stay as they were.

> [!TIP]
> Before you run a broad `-R -b` or `-R -x`, run `getfacl -R -p <dir> > /root/before.acl`. The next part shows why.

## Common pitfalls

> [!WARNING]
> - **Using `rx` on a mixed tree.** Every plain file becomes executable for that user. Use `rX`.
> - **Writing permission letters after `-x`.** `setfacl -x u:temp-vendor:r-x` is an error. Name the user only.
> - **Forgetting the default entries.** `-R -m` changes what exists now. New files need `-d -m` on each folder.
> - **Running `-R -b` to "reset" one user.** It removes every entry for everyone. Use `-x` for one name.
