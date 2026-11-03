# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module was about limits for the jobs that never pass the airlock: services, and the whole group of processes of one user.

**From [Limits For A Service](./course-01-limits-for-a-service.md):**

- `pam_limits` and `limits.d` only act at login. A service gets its limits from `systemd`.
- A drop-in at `/etc/systemd/system/<unit>.d/limits.conf` with `LimitNOFILE=` and `LimitNPROC=` sets them. You need `daemon-reload` and a restart.
- `/proc/<pid>/limits` shows what the running process really has.

**From [Limits For A User Slice](./course-02-limits-for-a-user-slice.md):**

- Each logged-in user has a slice named `user-<UID>.slice`. A slice limit caps the whole group of that user's processes.
- A drop-in in `/etc/systemd/system/user-<UID>.slice.d/` with `TasksMax=` or `MemoryMax=` caps one user. `user-.slice.d` caps everyone.
- `systemctl show user-<UID>.slice -p TasksMax` reads the result.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [systemd Service And User Limits Lab](../../../labs/lab-023/docs/question.md) | Limits For A User Slice | raised the open-file limit of a service so the running process carries it, and capped one user's slice with a saved drop-in |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. You add <code>nofile</code> lines to <code>/etc/security/limits.d/</code>. Does a running <code>systemd</code> service change?</summary>

No. `pam_limits` runs at login, and a service does not log in. Use `LimitNOFILE=` in a drop-in for the unit.
</details>

<details>
<summary>2. Which two steps make a new <code>LimitNOFILE</code> reach the process?</summary>

`sudo systemctl daemon-reload` so `systemd` reads the drop-in, then a restart of the service so a new process starts with the new limit.
</details>

<details>
<summary>3. Where do you read the limits a running process has?</summary>

In `/proc/<pid>/limits`.
</details>

<details>
<summary>4. What is the slice name for the user with UID 1500?</summary>

`user-1500.slice`.
</details>

<details>
<summary>5. Which folder caps every user, and which caps only UID 2010?</summary>

`/etc/systemd/system/user-.slice.d/` caps every user. `/etc/systemd/system/user-2010.slice.d/` caps only UID 2010.
</details>

<details>
<summary>6. How does a slice cap differ from <code>ulimit -u</code>?</summary>

A slice cap counts every process in the user's group together. `ulimit -u` is a per-user process count set for a shell and what it starts.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy systemd-limits-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-023
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-020/module-03/playground`. It always starts clean, so nothing you broke carries over.

> *Set the limit where the process is born, then read it from the process.*
