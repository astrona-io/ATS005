# Resource Limits For Services And Users With systemd

Astronaut, the limits you know from `limits.conf` are checked at the airlock: only a crew member who comes aboard through a login passes the PAM checklist. But a ship also runs jobs that nobody logs in for. The ship's core starts them, and the core is `systemd`. This module shows you the limits `systemd` applies to those jobs, and to every crew member's whole group of processes.

## Learning objectives

After this module you can:

- Explain why a `limits.d` file does not change a service that `systemd` starts.
- Set `LimitNOFILE` and `LimitNPROC` for one service with a drop-in file, and prove the new number on the running process.
- Explain what a user slice is, and how a slice limit differs from a per-process `ulimit`.
- Cap one user with a `TasksMax` drop-in on `user-<UID>.slice`, and read the result with `systemctl show`.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **Soft and hard limits.** A soft limit is the allowance a process starts with. A hard limit is the ceiling only `root` can raise.
- **Units.** A service is a unit that `systemctl` starts and stops, and `systemctl status <name>` shows it.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- A service `ledger-sync.service`, running `sleep infinity`, with no limits set by you.
- The user `dana`, with UID `2010`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh systemd-limits-playground
```

Every command block in the parts runs **inside that virtual machine**.

## How this module is laid out

1. [Limits For A Service](./course-01-limits-for-a-service.md): why `limits.d` misses services, and `LimitNOFILE` in a drop-in.
2. [Limits For A User Slice](./course-02-limits-for-a-user-slice.md): `user-<UID>.slice`, `TasksMax` and `systemctl show`.
   - Mission: [systemd Service And User Limits Lab](../../../labs/lab-023/docs/question.md)
3. [Wrap-Up: Mission Debrief](./course-03-wrap-up.md)

## Why this matters

On a real machine most processes belong to services. A limit that only works for logins protects nothing when a runaway service eats every file handle. The exam asks you to set a limit and prove that it reached the process.

> *A limit is only real when you can read it from the running process.*

<!-- curriculum-practice -->
## Practice and assessment

- [systemd Service And User Limits Lab](../../../labs/lab-023/docs/question.md): Raise the open-file limit of a running service and prove the process carries it; Cap one user's whole slice with a setting that survives a reload; Explain why limits.conf does not reach services.
- [Access Control & Resource Limits Capstone Lab](../../../labs/lab-020/docs/question.md): Give two outside users read-write and read-only access to a shared tree, inherited by new files; Turn a soft .bashrc process limit into a hard PAM limit; Limit a group to one login session at a time.
