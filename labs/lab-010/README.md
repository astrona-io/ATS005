---
estimated_duration: 45m
---

# Local Account & Group Lifecycle Capstone Lab

Welcome to the capstone mission of this section, astronaut. Mission control wants a full sweep of this ship's crew roster, from a new crew member's first day to an old one's last.

Your job is to move `analyst9` to a new group and home with its files, create `newhire9` with one exact `sudo` command, create, rename and delete groups without losing GIDs or members, lock `audit2`, set `shortterm3` to expire in 14 days, and remove `leaver5` with its home directory.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-010
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-010
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-010
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-010
```
