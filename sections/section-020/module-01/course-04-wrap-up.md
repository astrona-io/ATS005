# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module was about guest lists on files and directories: extra access for named users that sits on top of the three standard buckets.

**From [Reading And Granting ACL Entries](./course-01-reading-and-granting-acl-entries.md):**

- `getfacl` prints a file's full access picture. A `+` at the end of the mode in `ls -l` means the file has an extended ACL.
- `setfacl -R -m u:<user>:<perms> <dir>` adds a named-user entry to a directory and everything already inside it.
- Directories need the execute bit (`rwx` or `r-x`) so the user can pass into them.

**From [Default ACLs For Files Created Later](./course-02-default-acls.md):**

- `setfacl -d -m` sets default entries. The kernel copies them onto every new file and subdirectory.
- Existing files need `-R -m`; future files need `-d -m`. Most mistakes are one missing half.
- ACLs only add access. The owner, the group and the base mode do not change.

**From [The ACL Mask](./course-03-the-acl-mask.md):**

- The `mask` caps named entries and the owning group, but not the owner or `other`.
- `setfacl -m` recalculates the mask by itself. A mask narrowed by hand caps entries, and `getfacl` marks them with `#effective:`.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [ACL-Based Shared Directory Access Lab](../../../labs/lab-021/docs/question.md) | Default ACLs For Files Created Later | gave `contractor-jane` read and write and `auditor-tom` read only on a whole tree, and made new files inherit both |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. How can you tell from <code>ls -l</code> that a file has an extended ACL?</summary>

The mode string ends with a `+`, for example `drwxrwx---+`.
</details>

<details>
<summary>2. You run <code>setfacl -m u:jane:rwx /srv/project</code> on a full directory. Can Jane open the files already inside?</summary>

No. Without `-R`, only the directory itself gets the entry. Run it again with `-R`.
</details>

<details>
<summary>3. Why does a read-write grant on a directory need <code>rwx</code> and not <code>rw-</code>?</summary>

On a directory, `x` means "may pass through". Without it the user cannot `cd` into the directory or reach the files inside.
</details>

<details>
<summary>4. Which <code>setfacl</code> option makes new files get an entry automatically?</summary>

`-d` (default), for example `setfacl -d -m u:jane:rwx /srv/project`.
</details>

<details>
<summary>5. <code>getfacl</code> shows <code>user:jane:rwx #effective:r-x</code>. What is limiting Jane?</summary>

The `mask` entry. It has been narrowed to `r-x` and caps every named entry. Running `setfacl -m` on any entry recalculates it.
</details>

<details>
<summary>6. Does adding ACL entries change the directory's owner or group?</summary>

No. ACLs only add entries. The owner, the group and the base mode stay the same.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy posix-acl-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-021
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-020/module-01/playground`. It always starts clean, so nothing you broke carries over.

> *Fix both halves: `-R -m` for the crates already aboard, `-d -m` for every crate packed tomorrow.*
