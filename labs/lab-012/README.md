---
estimated_duration: 15m
---

# Group Creation, Membership & the Active-Group Trap Lab

Welcome to a crew team mission, astronaut. This ship needs a new team with a fixed number, an old team with a new name, and one unused team disbanded.

Your job is to create `datateam` with GID `5000` for `marta` and `cilla` without changing their other groups, rename `legacy-ops` to `platform-ops` with its GID and members intact, and delete `temp-audit`.

## Launching the Lab

Run this command to start the virtual machine:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-012
```

Open a terminal on it:

```bash
astrona ssh ats-005-lab-012
```

When you think you have finished, send it for grading:

```bash
astrona submit -c labs/lab-012
```

When you are done, remove the lab:

```bash
astrona destroy ats-005-lab-012
```
