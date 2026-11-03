---
estimated_duration: 20m
---

# systemd Service And User Limits Lab

Welcome to a limits mission, astronaut. One service on this ship runs out of open files, and one crew member keeps launching too many helpers. Neither is stopped by a login checklist, so the ship's core must do it.

Your job is to raise one service's open-file limit so the running process carries it, and to cap one user's whole slice, with settings that survive a reload.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-023
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-023
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-023
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-023
```
