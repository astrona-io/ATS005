---
estimated_duration: 20m
---

# ACL-Based Shared Directory Access Lab

Welcome to a guest list mission, astronaut. The Orion project compartment on this ship belongs to one team, and two outside crew members need their own access without joining it.

Your job is to give `contractor-jane` read and write access and `auditor-tom` read-only access to the whole `/srv/projects/orion` tree with ACL entries, and to make every new file inherit both.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-021
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-021
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-021
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-021
```
