---
estimated_duration: 20m
---

# Account Defaults, Password Aging & Locking Lab

Welcome to an account life mission, astronaut. Three crew members on this ship are at different stages of their time aboard: one is new, one is under investigation, and one has left for good.

Your job is to create `contractor7` with the system's real defaults, a forced password change and a 30-day account expiry, lock `contractor3` without deleting it, and remove `contractor1` with its home directory.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-013
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-013
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-013
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-013
```
