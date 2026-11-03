# Limits For A Service

Astronaut, a service is a crew member that the ship's core starts at launch. Nobody walks it through the airlock, so the airlock checklist never sees it. This part shows you where a service gets its limits instead, and how to change them for one service only.

## Services do not pass through the airlock

`pam_limits` reads `/etc/security/limits.conf` when someone logs in. A service started by `systemd` does not log in, so those files do not apply to it. `systemd` sets the limits itself, from the unit file. For the limit on open files, the setting is `LimitNOFILE`.

### Read the limit on the running process

First find the process of `ledger-sync`, then read its limits from the kernel:

<!-- astrona:playground:renew -->

```sh
systemctl show ledger-sync -p MainPID -p LimitNOFILE
grep 'Max open files' /proc/$(systemctl show ledger-sync -p MainPID --value)/limits
```

Expect something like:

```text
MainPID=...
LimitNOFILE=...
Max open files            ...       ...       files
```

`/proc/<pid>/limits` is the kernel's own record. The two numbers after the name are the soft limit and the hard limit. Write them down: you will compare them in a moment.

## Set a limit for one service

You do not edit the unit file that the package ships. You add a **drop-in**: a small file in a folder named after the unit, with the suffix `.d`. Package updates leave it alone.

### Write the drop-in

Create the folder:

```sh
sudo install -d /etc/systemd/system/ledger-sync.service.d
```

Save this as `/etc/systemd/system/ledger-sync.service.d/limits.conf`:

```ini
[Service]
LimitNOFILE=4096
LimitNPROC=200
```

Apply it. `systemd` reads the new file only after a reload, and the running process only gets the limits when it starts again:

```sh
sudo systemctl daemon-reload && sudo systemctl restart ledger-sync
```

Then check the result:

```sh
systemctl show ledger-sync -p LimitNOFILE -p LimitNPROC
grep -E 'Max (open files|processes)' /proc/$(systemctl show ledger-sync -p MainPID --value)/limits
```

Expect `LimitNOFILE=4096` and `LimitNPROC=200`, and in the kernel's table a soft and a hard value of `4096` for open files and `200` for processes. The restart gave the service a new process, and the new process carries the new numbers.

### What the two settings mean

`LimitNOFILE` is the highest number of open files and network connections. `LimitNPROC` is the highest number of processes that one user ID may own, counted across the whole machine, not only inside this service. A single number sets the soft and the hard limit together.

## Common pitfalls

> [!WARNING]
> - **Putting the limit in `/etc/security/limits.d/`.** `pam_limits` only runs at login, so a service never sees it. Use the unit's drop-in.
> - **Forgetting `daemon-reload`.** `systemd` keeps reading the old unit until you run `sudo systemctl daemon-reload`.
> - **Forgetting the restart.** A process keeps the limits it started with. Restart the service and read `/proc/<pid>/limits` again.
> - **Editing the shipped unit file.** An update can overwrite it. Use a drop-in under `/etc/systemd/system/<unit>.d/`.
