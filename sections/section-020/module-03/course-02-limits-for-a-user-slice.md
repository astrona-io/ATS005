# Limits For A User Slice

Astronaut, `ulimit` guards one crew member's single helper at a time. Sometimes the captain needs a cap on everything one crew member runs together. This part shows you the group of cabins that `systemd` gives each user, and how to put a ceiling on all of it.

## One slice for each user

`systemd` puts every process of a logged-in user into one **slice**: a group of processes with shared limits, called a control group (cgroup). The slice of the user with UID `2010` is named `user-2010.slice`. A slice limit counts the whole group, so ten small processes and one big process are added together.

That is different from `nproc` in `limits.conf`, which counts processes per user ID at login, and from `ulimit`, which is set for one shell and what it starts.

### Read a user's slice settings

Find the UID of `dana`, then read two settings of her slice:

<!-- astrona:playground:renew -->

```sh
id -u dana
systemctl show user-2010.slice -p TasksMax -p MemoryMax
```

Expect something like:

```text
2010
TasksMax=...
MemoryMax=infinity
```

`TasksMax` is the most processes and threads the slice may hold. The number you see comes from a system default. `MemoryMax=infinity` means no memory cap is set.

## Cap one user

A drop-in under `user-<UID>.slice.d` limits one user. The same file under `user-.slice.d` (with nothing between the dash and the dot) would limit every user.

### Write the drop-in

Create the folder:

```sh
sudo install -d /etc/systemd/system/user-2010.slice.d
```

Save this as `/etc/systemd/system/user-2010.slice.d/50-limits.conf`:

```ini
[Slice]
TasksMax=100
MemoryMax=512M
```

Apply it:

```sh
sudo systemctl daemon-reload
```

Then check the result:

```sh
systemctl show user-2010.slice -p TasksMax -p MemoryMax
```

Expect `TasksMax=100` and `MemoryMax=536870912`. `systemctl show` prints memory in bytes, and 512M is 536870912 bytes. The slice may be idle when `dana` is not logged in, but the cap is ready the moment she comes aboard.

### A quicker way for a live change

`sudo systemctl set-property user-2010.slice TasksMax=100` sets the value at once and saves it in a drop-in under `/etc/systemd/system.control/`. Add `--runtime` and the change is gone at the next reboot. Use the file when you want to keep the file in your own hands.

## Common pitfalls

> [!WARNING]
> - **Using the user name in the file name.** The slice is named after the UID: `user-2010.slice.d`, not `user-dana.slice.d`.
> - **Forgetting the dash in `user-.slice.d`.** That folder name is the template for all users. Check twice before you save a cap for everybody.
> - **Reading the cap from `limits.conf` tools.** `ulimit -u` shows the per-user process limit, not the slice cap. Use `systemctl show`.
> - **Expecting an instant effect on a long session.** Run `daemon-reload` and check with `systemctl show`. A new login is the cleanest proof.

## Your mission: systemd Service And User Limits Lab

You can now limit one service and one user with `systemd` drop-ins, and prove both. The mission asks for a service limit that really reached the process, and a persistent cap on one user's slice.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop systemd-limits-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-023
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-023
```

Read the task in [`question.md`](../../../labs/lab-023/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-023
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-023
astrona start systemd-limits-playground
```
