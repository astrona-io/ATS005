---
estimated_duration: 25m
---

# Shell Environment & PATH Capstone Lab

Welcome to the capstone mission for the briefing pack, astronaut. Every crew member who comes aboard needs an onboarding address, one crew member wants their own editor, and that same crew member's tools deck must join the search list safely.

Your job is to export `ONBOARD_PORTAL` from a `/etc/profile.d/` script, set `EDITOR=nano` for `candidate` only, and append `~/bin` to `candidate`'s `PATH` so `deploy-helper` runs by name and a decoy never beats a real command.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-030
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-030
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-030
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-030
```
