# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module was about guest lists on a whole cargo hold: reading them, changing them, and keeping a photograph so a cleanup accident does not cost you anything.

**From [ACLs On A Whole Tree](./course-01-acls-on-a-whole-tree.md):**

- `getfacl -R -p <dir>` prints the ACL of every path in the tree, with full paths.
- `setfacl -R -m u:<user>:rX` gives folders and programs `r-x` and plain files `r--`.
- `setfacl -R -x u:<user>` removes one name everywhere. `setfacl -R -b` removes every extended entry.

**From [Backup And Restore](./course-02-backup-and-restore.md):**

- `getfacl -R -p <dir> > file` is the backup. Write it as `root`, and take it before you change anything.
- `setfacl --restore=<file>` puts every entry, owner and group back. It cannot be mixed with other options.
- The backup holds ACLs only, not file contents.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [ACL Tree Backup And Restore Lab](../../../labs/lab-024/docs/question.md) | Backup And Restore | saved the ACLs of a tree, recovered from a cleanup accident with `--restore`, and removed one user from the whole tree |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Why use <code>rX</code> and not <code>rx</code> on a tree of mixed files?</summary>

The capital `X` gives execute only to folders and to files that are already executable. Plain `rx` makes every data file executable for that user.
</details>

<details>
<summary>2. Which command removes the entries of <code>temp-vendor</code> from every path in <code>/srv/data/ledger</code>?</summary>

`setfacl -R -x u:temp-vendor /srv/data/ledger`. Name the user and no permission letters.
</details>

<details>
<summary>3. What does <code>setfacl -R -b</code> remove?</summary>

Every extended ACL entry, for everyone. Only the owner, group and other bits stay.
</details>

<details>
<summary>4. Which command saves the ACLs of a tree so they can be restored from any folder?</summary>

`getfacl -R -p <dir> > <file>`. The `-p` keeps the leading `/`.
</details>

<details>
<summary>5. How do you restore from the backup file?</summary>

`sudo setfacl --restore=<file>`.
</details>

<details>
<summary>6. Does the backup file protect the contents of the files?</summary>

No. It holds the ACLs, owners, groups and special bits only.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy acl-backup-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-024
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-020/module-04/playground`. It always starts clean, so nothing you broke carries over.

> *Photograph the guest lists first, then tidy the hold.*
