# Login Shells, Non-Login Shells And Personal Variables

Astronaut, a crew member can come aboard through the main airlock, or open a new console on a ship they are already on. Each door reads different briefing files. This part shows you which files each kind of shell reads, and where a variable for one crew member only belongs.

## The difference that decides everything

Every dotfile decision depends on one fork: is the shell a **login shell** or an **interactive non-login shell**? The two read different files, and neither one implies the other.

### Watch each path read a different file

Put a different value for the same variable in two of `candidate`'s files, then start a login shell, and a `bash` inside it:

<!-- astrona:playground:renew -->

```sh
echo 'export MARKER=from-bash_profile' >> /home/candidate/.bash_profile
echo 'export MARKER=from-bashrc'       >> /home/candidate/.bashrc
su - candidate -c 'echo "$MARKER"'
su - candidate -c 'bash -c "echo $MARKER"'
```

Expect something like:

```text
from-bash_profile
from-bashrc
```

The login shell (`su - candidate`) read `~/.bash_profile`. The second line is meant to show the child `bash`, a non-login shell, reading `~/.bashrc` instead: same account, two files, two values. On a real machine this second line may print `from-bash_profile` too. The login shell expands `$MARKER` inside the double quotes before the child `bash` starts, and a non-interactive `bash -c` does not read `~/.bashrc` at all. Opening a new interactive `bash` and typing `echo $MARKER` shows the `~/.bashrc` value more reliably.

### Which files each shell reads

Here is the rule behind it:

- A **login shell** starts as if the user just signed in: a fresh SSH connection with no command, a console login, or `su -`. Think of it as coming aboard through the main airlock. Bash reads `/etc/profile` (and what it sources, including `/etc/profile.d/*.sh`), then the *first* of `~/.bash_profile`, `~/.bash_login` and `~/.profile` that exists. Only that one.
- An **interactive non-login shell** is a new terminal tab in a desktop session that is already signed in, or `bash` typed inside an open shell. Think of it as opening a new console on a ship you are already on. It never reads `/etc/profile` or `~/.bash_profile`; it reads `~/.bashrc`.

```text
Login shell:            /etc/profile → /etc/profile.d/*.sh → ~/.bash_profile (first match)
Non-login interactive:  ~/.bashrc only
```

That is why a variable that "worked when I logged in over SSH" can vanish when a colleague opens a second terminal tab. There are two startup paths, with two sets of files.

## A personal variable, placed correctly

A preference that one user wants and nobody else, such as `EDITOR=vim`, belongs in that user's own personal briefing, not in a ship-wide file.

### Add the line for `candidate` only

Append the line to `candidate`'s `~/.bash_profile`:

```sh
echo 'export EDITOR=vim' >> /home/candidate/.bash_profile
```

That line makes two decisions. It touches only this user's file, so no other account is affected. And `~/.bash_profile` is a real shell script, so `export` is required. Without it, `EDITOR` would live only in that one shell and never reach a program it starts.

### One account, not the others

Read the variable from a fresh login shell for each account:

```sh
su - candidate -c 'echo "candidate: $EDITOR"'
su - otheruser -c 'echo "otheruser: $EDITOR"'
```

Expect something like:

```text
candidate: vim
otheruser:
```

`candidate`'s login shell read `candidate`'s `~/.bash_profile`. `otheruser` has no such line in their own dotfiles, so the variable is not set for them. The change really is per user.

## Common pitfalls

> [!WARNING]
> - **Putting a personal preference in a ship-wide file.** It reaches every account. A personal variable goes in the user's own `~/.bash_profile` or `~/.bashrc`.
> - **Creating `~/.bash_profile` and losing `~/.profile`.** Bash reads only the *first* of `~/.bash_profile`, `~/.bash_login` and `~/.profile`. Once `~/.bash_profile` exists, a login shell no longer reads `~/.profile`.
> - **Leaving out `export` in a dotfile.** The variable then stays in the shell and never reaches the programs it starts.
> - **Testing from the shell you edited in.** Dotfiles are read when a shell starts. Test with a fresh `su -` or a new tab.

## Your mission: System-Wide and Personal Environment Variables Lab

You can now put a plain variable on the ship-wide notice board for every kind of shell, and a personal variable in one user's own login profile. Now prove it in a graded mission: a fresh ship where every user needs a proxy variable in login and non-login shells, and `candidate` alone wants an editor preference.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop env-profiles-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-031
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-031
```

Read the task in [`question.md`](../../../labs/lab-031/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-031
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-031
astrona start env-profiles-playground
```
