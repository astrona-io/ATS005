# Creating A New Account In One Command

Astronaut, adding a new crew member is easier than fixing an old one, because there is nothing to break yet. This part shows you how to build a whole account with one `useradd` command, and then the one flag that can quietly take badges away from an existing crew member.

## Building the whole account at once

The `useradd` command (short for *user add*) creates a new entry on the crew roster. A new account has no earlier state to damage, so one call can set everything.

### Create `user2` in one call

Create the account with its home, groups and shell, then check it:

<!-- astrona:playground:renew -->

```sh
sudo useradd -m -d /home/accounts/user2 -G dev,op -s /bin/bash user2
id user2
getent passwd user2
```

Expect something like:

```text
uid=1002(user2) gid=1002(user2) groups=1002(user2),1003(dev),1004(op)
user2:x:1002:1002:...:/home/accounts/user2:/bin/bash
```

`groups=` lists both `dev` and `op`. The account record shows the home path and the shell you asked for. One command did all of it.

### What each option did

Here is what each part of that command means:

- `-m` creates the home directory and fills it from `/etc/skel`, the welcome kit placed in every new crew member's quarters. There is nothing to move, because the account is new.
- `-d /home/accounts/user2` sets the home path at creation time, so no separate move step is needed.
- `-G dev,op` sets the **supplementary** groups: the extra team badges. Separate them with commas and no spaces.
- `-s /bin/bash` sets the login shell: the console the crew member sits at when they come aboard.

`useradd` has no `-a` (append) option, and it needs none. A new account has no group list to protect, so every group in `-G` simply becomes part of it from the start.

## The `-G` and `-aG` trap on existing users

The same `-G` option that is harmless on `useradd` becomes dangerous on `usermod`. On an account that **already exists**, it decides whether you add a badge or take all the others away.

### Replace or append

Compare these two commands:

```sh
sudo usermod -G datateam user1     # REPLACES the entire supplementary list
sudo usermod -aG datateam user1    # APPENDS datateam, keeps the rest
```

Say `user1` belongs to five groups and you run plain `-G datateam`. All five are gone, replaced by a list with only `datateam` on it. The `-a` (append) option is what makes the change add to the list. `usermod` gives no warning either way. These two lines only show the difference; your playground has no `datateam` group.

### See append keep the existing list

Read the groups, add `op` with `-aG`, and read them again:

```sh
id user1
sudo usermod -aG op user1
id user1
```

Expect something like:

```text
uid=1001(user1) gid=1003(dev) groups=1003(dev),1002(web)
uid=1001(user1) gid=1003(dev) groups=1003(dev),1002(web),1004(op)
```

`op` is added, and both `web` and the primary group `dev` stay. Run it with `-G op` instead of `-aG op` on a throwaway user, and you will see `web` disappear. That is the trap.

> [!TIP]
> Before any `usermod -G`, run `id` on the user and keep the output. If you lose a group by mistake, that line tells you exactly what to put back.

## Common pitfalls

> [!WARNING]
> - **`usermod -G` on an existing user.** It replaces the whole supplementary list. Use `usermod -aG` to add a group.
> - **Spaces in the group list.** Write `-G dev,op`, not `-G dev, op`. The shell splits on the space.
> - **Forgetting `-m` on `useradd`.** Without it, the account record points at a home directory that was never created.
