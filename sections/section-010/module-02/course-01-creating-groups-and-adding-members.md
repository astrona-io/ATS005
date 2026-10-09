# Creating Groups And Adding Members

Astronaut, a group is a crew team, and its GID is the team's number. This part shows you how to create a team with the exact number a task asks for, how to check it the way the system itself does, and how to add crew members without taking their other badges away.

## Creating a group with an exact GID

`groupadd` (short for *group add*) creates a new team. You can let it pick the number, or you can pin the number yourself.

### Pin a GID and read it back

Create the group `datateam` with GID `5000`, then read it back:

<!-- astrona:playground:renew -->

```sh
sudo groupadd -g 5000 datateam
getent group datateam
```

Expect something like:

```text
datateam:x:5000:
```

The third field, between the colons, is the GID: exactly `5000`, not "whatever number was free next". The empty fourth field is the member list. Nobody is in it yet.

### Where the GID comes from

Without `-g`, `groupadd` takes the next free GID from the range set in `/etc/login.defs` (`GID_MIN` and `GID_MAX`). That is fine when the number does not matter. Many real tasks need a *specific* GID, usually because file ownership or another system already expects it. The `-g` option pins it.

### Check with `getent`, not `grep`

Check a group with `getent group`, not with `grep` on `/etc/group`. `getent` (short for *get entries*) asks the ship's records officer. It follows the same NSS (Name Service Switch) lookup chain the system uses at run time: the list of rosters to ask, in order. So it stays correct even when groups come from somewhere other than the local file, for example a central directory. `grep` on the file only ever shows local entries.

## Adding members without losing their other groups

Adding existing users to a new group has one trap: the option that replaces a user's whole group list looks almost the same as the one that adds to it.

### Append, never replace

Add both users with `-aG`:

```sh
sudo usermod -aG datateam marta
sudo usermod -aG datateam cilla
```

`-aG` (append) keeps each user's primary group and every other supplementary group. Without the `-a`, plain `-G datateam` **replaces** the whole supplementary list. Both users would lose every other team badge, and `usermod` gives no warning.

### The group-side tool: `gpasswd`

`gpasswd` (short for *group password*) manages `/etc/group` and `/etc/gshadow`, one group at a time:

```sh
sudo gpasswd -a marta datateam
```

`gpasswd -a` does the same job as `usermod -aG`, for one group. It cannot touch any other group, so some administrators prefer it for one-off additions.

### Add two members two ways

Look at `marta` first, add her with `usermod -aG`, add `cilla` with `gpasswd -a`, then look again:

```sh
id marta
sudo usermod -aG datateam marta
sudo gpasswd -a cilla datateam
id marta
getent group datateam
```

Expect something like:

```text
uid=1001(marta) gid=1001(marta) groups=1001(marta),1010(staff),1011(projectx)
...
uid=1001(marta) gid=1001(marta) groups=1001(marta),1010(staff),1011(projectx),5000(datateam)
datateam:x:5000:marta,cilla
```

`datateam` is added to `marta`'s list, and `staff` and `projectx` are still there. The group's own member field now lists both users. If you already ran the two `usermod -aG` lines above, the commands simply confirm what is there.

## Common pitfalls

> [!WARNING]
> - **`usermod -G` on an existing user.** It replaces every supplementary group. Use `usermod -aG` or `gpasswd -a`.
> - **Letting `groupadd` pick the number when the task gives one.** Use `-g <GID>` whenever a GID is named.
> - **Checking with `grep /etc/group`.** It misses groups from other sources. Use `getent group <name>`.
