---
estimated_duration: 20m
---

# User & Group Provisioning and Scoped Sudo Lab

Welcome to a crew roster mission, astronaut. One crew member on this ship has the wrong team and the wrong quarters, a new crew member must come aboard, and that new crew member needs the captain's authority for exactly one order.

Your job is to move `user1` to a new primary group and home with all its files, create `user2` with the right groups, home and shell, and write one exact `NOPASSWD` rule in a `/etc/sudoers.d/` drop-in.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-011
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-011
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-011
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-011
```
