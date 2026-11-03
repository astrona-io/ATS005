# Default ACLs For Files Created Later

Astronaut, a guest list taped to a compartment today does nothing for a crate packed tomorrow. This part shows you how to give a directory a default guest list that every new file is born with, and how to prove that ACLs only ever add access.

## Making the access stick for new files

The named entries you add with `setfacl -R -m` cover the files that exist *now*. A brand-new file created under `/srv/projects/orion` tomorrow starts with **no** named entries. Entries are not passed down just because the parent directory has some.

### Add default entries and create a new file

A **default ACL** is a template that the kernel (the ship's core) reads when a file is created. The `-d` (**d**efault) option sets a default entry instead of a normal access entry. Set the two defaults, create a new file as `contractor-jane`, and read its ACL:

<!-- astrona:playground:renew -->

```sh
sudo setfacl -d -m u:contractor-jane:rwx /srv/projects/orion
sudo setfacl -d -m u:auditor-tom:rx /srv/projects/orion
sudo -u contractor-jane touch /srv/projects/orion/new-note.txt
getfacl /srv/projects/orion/new-note.txt
```

Expect something like:

```text
# file: srv/projects/orion/new-note.txt
# owner: contractor-jane
# group: orion-team
user::rw-
user:contractor-jane:rwx			#effective:rw-
user:auditor-tom:r-x
group::r-x
mask::rw-
other::---
```

Nobody ran `setfacl` on `new-note.txt`, yet it already has both named-user entries. The default ACL gave them to it when it was created. The `#effective:` note and `mask::rw-` are the mask at work: a new regular file gets no execute bit, so the mask caps the entries at `rw-`.

### How default entries are passed down

When a file is created, the kernel copies the directory's default entries onto it as that file's own access ACL. When a subdirectory is created, it gets an access ACL *and* its own copy of the defaults, so the chain keeps going down the tree.

The two kinds of `setfacl` call are not interchangeable:

| What you ran | What it covers |
| :--- | :--- |
| `setfacl -R -m …` (no `-d`) | Files and subdirectories that already exist |
| `setfacl -d -m …` (with `-d`) | Files and subdirectories created from now on |

Set only the first, and the fix stops working the moment someone adds a file. Set only the second, and everything already in the tree stays closed.

## Proving the change only added access

The task was that the owner, the group and the base mode do not change, and that existing `orion-team` members notice no difference. ACLs only add; they never rewrite the traditional fields. `ls -ld` confirms it: the owner is still `team-lead`, the group is still `orion-team`, and the base bits are still `rwxr-x---`. Only the `+` is new.

### Jane can write, Tom cannot

The real proof is a live test of who can do what. Write a file as `contractor-jane`, read it as `auditor-tom`, and try to write as `auditor-tom`:

```sh
sudo -u contractor-jane touch /srv/projects/orion/jane-file.txt && echo "jane: wrote OK"
sudo -u auditor-tom cat /srv/projects/orion/jane-file.txt && echo "tom: read OK"
sudo -u auditor-tom touch /srv/projects/orion/tom-file.txt
```

Expect something like:

```text
jane: wrote OK
(file contents — empty here)
tom: read OK
touch: cannot touch '/srv/projects/orion/tom-file.txt': Permission denied
```

`contractor-jane` (`rwx`) creates a file. `auditor-tom` (`r-x`) reads it but is refused the write. Neither user is in `orion-team`: the access came entirely from the named-user ACL entries.

> [!TIP]
> Most real ACL mistakes are one missing half. After any ACL change on a shared tree, ask two questions: "do the files already there have the entry?" and "will a new file get it?"

## Common pitfalls

> [!WARNING]
> - **Only an access ACL, or only a default ACL.** You fixed one half. Existing files need `-R -m`; future files need `-d -m`.
> - **Testing as yourself.** Your own account may be the owner or have `sudo`. Test with `sudo -u <user>` as the user who should, or should not, get in.
> - **Expecting `#effective:` to be an error.** On a new regular file the mask is often `rw-`, so an `rwx` entry shows `#effective:rw-`. That is normal.

## Your mission: ACL-Based Shared Directory Access Lab

You can now give two users different access to a whole tree with named entries, and make every new file inherit them. Now prove it in a graded mission: a fresh shared project tree where an outside contractor needs read and write, an auditor needs read only, and neither may join the team.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop posix-acl-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-021
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-021
```

Read the task in [`question.md`](../../../labs/lab-021/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-021
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-021
astrona start posix-acl-playground
```
