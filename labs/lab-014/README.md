---
estimated_duration: 20m
---

# Group Sudo Rules With Aliases Lab

Welcome to a standing orders mission, astronaut. The `webops` team must check and restart the `ssh` service, one outside crew member may only read its log, and the captain's orders must stay valid.

Your job is to write one drop-in file with a command alias, give it to the group without a password, give the log command to one user with a password, and prove that `visudo -c` is happy.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-014
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-014
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-014
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-014
```
