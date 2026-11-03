---
estimated_duration: 40m
---

# Access Control & Resource Limits Capstone Lab

Welcome to the capstone mission for guest lists and crew allowances, astronaut. A shared compartment needs two outside users, one crew member's process limit lives in a startup file, and a support team needs a login cap.

Your job is to give `vendor-lee` and `qa-nina` their own access to `/srv/data/atlas` with ACLs that new files inherit, turn `derek`'s `.bashrc` limit into a hard `nproc` limit in `/etc/security/limits.d/`, and allow each member of `supportstaff` only one login at a time.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-020
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-020
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-020
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-020
```
