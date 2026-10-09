---
estimated_duration: 20m
---

# PAM Hard Limits & maxlogins Lab

Welcome to an allowance mission, astronaut. One crew member on this ship started far too many helpers, and the only fix so far is a line in her personal startup file.

Your job is to turn that number into a hard `nproc` limit in `/etc/security/limits.d/`, remove the old `.bashrc` line, and allow each member of `operators` only one login at a time.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-022
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-022
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-022
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-022
```
