---
estimated_duration: 15m
---

# System-Wide and Personal Environment Variables Lab

Welcome to a briefing pack mission, astronaut. Every crew member on this ship needs the company proxy in every kind of shell, and one crew member wants their own editor.

Your job is to put `COMPANY_PROXY` on the ship-wide notice board, `/etc/environment`, and set `EDITOR=vim` for `candidate` only, in that user's own login profile.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-031
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-031
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-031
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-031
```
