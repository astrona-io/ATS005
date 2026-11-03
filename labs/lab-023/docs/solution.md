# Solution Walkthrough

This walkthrough sets two limits through `systemd` drop-ins. A drop-in is a small file in a folder named after the unit; it adds settings without touching the file the package ships. Run every command on the lab machine (`astrona ssh ats-005-lab-023`).

---

## Step 1: Read the service limit as it is now

Find the main process and read what the kernel says about its open files:

```bash
systemctl show ledger-sync -p MainPID -p LimitNOFILE
grep 'Max open files' /proc/$(systemctl show ledger-sync -p MainPID --value)/limits
```

- `/proc/<pid>/limits` is the kernel's record for the running process. It is the proof the grader trusts.
- The numbers you see now are not `4096`.

---

## Step 2: Write the service drop-in

Create the folder and the file:

```bash
sudo install -d /etc/systemd/system/ledger-sync.service.d
sudo vi /etc/systemd/system/ledger-sync.service.d/limits.conf
```

Write these two lines, then save and quit:

```ini
[Service]
LimitNOFILE=4096
```

- `LimitNOFILE=4096` sets the soft and the hard limit for open files to `4096`.
- A line in `/etc/security/limits.d/` would not help: `pam_limits` only runs when someone logs in.

---

## Step 3: Reload, restart and prove it

`systemd` reads the new file after a reload. The running process only changes when it starts again:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ledger-sync
grep 'Max open files' /proc/$(systemctl show ledger-sync -p MainPID --value)/limits
```

- The new process shows `4096` for both the soft and the hard limit.

---

## Step 4: Cap the user slice of dana

The slice of the user with UID `2010` is `user-2010.slice`. Create its drop-in folder and file:

```bash
sudo install -d /etc/systemd/system/user-2010.slice.d
sudo vi /etc/systemd/system/user-2010.slice.d/50-limits.conf
```

Write these two lines, then save and quit:

```ini
[Slice]
TasksMax=100
```

Reload and read the result:

```bash
sudo systemctl daemon-reload
systemctl show user-2010.slice -p TasksMax
```

- You should see `TasksMax=100`.
- The file name uses the UID, not the user name.
- `sudo systemctl set-property user-2010.slice TasksMax=100` also works, because it saves a drop-in under `/etc/systemd/system.control/`. Do not add `--runtime`, since that change is lost at reboot.

From your own computer, not the lab machine, send the lab for grading:

```bash
astrona submit -c labs/lab-023
```
