---
estimated_duration: 15m
---

# Safe PATH Extension & Precedence Lab

Welcome to a search-order mission, astronaut. A crew member keeps their own tools in `~/work` and wants to call them by name, without ever letting a script there answer to a real command's name.

Your job is to append `~/work` to `candidate`'s `PATH` in a login-shell file, run `helper-tool` by name from a fresh session, and prove that a decoy `ls` in `~/work` never wins.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-032
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-032
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-032
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-032
```
