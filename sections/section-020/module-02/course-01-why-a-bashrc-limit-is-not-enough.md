# Why A .bashrc Limit Is Not Enough

Astronaut, a coworker already tried to stop `jackie` from starting too many helpers. This part shows you where their fix has a hole, why a soft limit is no real ceiling, and how to read the number a user is really running with.

## The hole in a `.bashrc` fix

Say a coworker capped `jackie`'s runaway processes by adding one line to `~/.bashrc`:

```text
ulimit -Su 150
```

`ulimit` is the shell's built-in command that reads and sets resource limits for the shell and everything it starts. The options that matter here are `-u` (the maximum number of user processes, the `nproc` limit), `-S` (the *soft* value) and `-H` (the *hard* value).

### Which shells read `~/.bashrc`

The line works: the next *interactive* shell `jackie` opens is capped at 150 processes. The problem is the word *interactive*. Bash reads `~/.bashrc` for interactive non-login shells: "you are already aboard, and a new console opens", like a second terminal tab in an open SSH session. That leaves out:

- a cron job running as `jackie`,
- a non-interactive remote command, such as `ssh web-srv1 somecommand`,
- many user sessions started by systemd,
- `su -` in some setups.

None of those read `~/.bashrc`. The restriction has a hole exactly where a scripted or automated process, the kind most likely to fork out of control, would run.

### Soft limits are not a ceiling

There is a second problem, even where `~/.bashrc` *is* read. The coworker set only a **soft** limit: the allowance a crew member starts with. Any normal user may raise their own soft limit, up to the hard ceiling. The **hard** limit is the real backstop: the ceiling only the captain (`root`) can raise. Nobody touched it.

### See the hole and the soft-limit weakness

Look at the end of `jackie`'s `~/.bashrc`, then read the soft limit through a login shell and through a plain `bash -c`, and finally read the hard limit:

<!-- astrona:playground:renew -->

```sh
tail -n 3 /home/jackie/.bashrc
sudo -u jackie -i ulimit -Su
sudo -u jackie bash -c 'ulimit -Su'
sudo -u jackie -i ulimit -Hu
```

Expect something like:

```text
# added by a coworker to stop runaway forks (fragile: interactive shells only)
ulimit -Su 150
150
14611
unlimited
```

The login-shell path (`-i`) picks up the `~/.bashrc` line and reports `150`. The plain `bash -c` path stands in for cron or `ssh host cmd`. It never reads `~/.bashrc`, so it shows the untouched default (a large number that depends on the machine's memory). The *hard* limit is still `unlimited`: nothing stops `jackie` from running `ulimit -Su 500` herself.

## Finding the number you really need

A real task usually wants `jackie`'s *current* soft limit reused as the new hard limit. That means the live value, not a number in a dotfile that may be out of date. There are two independent ways to read it.

### Two readings of the same limit

Read it from `jackie`'s own login shell, then straight from the kernel for one of her running processes:

```sh
sudo -u jackie -i ulimit -Su
sudo prlimit --pid "$(systemctl show -p MainPID --value jackie-sleeper)" --nproc
```

Expect something like:

```text
150
RESOURCE   DESCRIPTION                             SOFT      HARD UNITS
NPROC      max number of processes                  150 unlimited processes
```

`sudo -u jackie -i` opens a login shell as `jackie`, which reads her startup files and reports the active soft `nproc` limit as a plain number.

`prlimit` (short for *process limit*) gets or sets the kernel's resource limits for a running process ID. The inner command only finds that ID: `systemctl show -p MainPID --value <unit>` prints one property of a unit (`-p` names it, `--value` prints the bare value), here the process ID of the `jackie-sleeper` unit. `prlimit` does not care which shell, if any, started the process. That makes it the more trustworthy source before you write a number into a file that will govern the account.

The `jackie-sleeper` process was started by systemd, not by an interactive shell. If your `prlimit` reading shows a different soft value from the login shell, that difference is the very hole described above: systemd never read `~/.bashrc`.

> [!TIP]
> Before you copy a limit from a dotfile into a configuration file, read the live value with `ulimit` or `prlimit`. The dotfile line may be out of date, or may never have worked.

## Common pitfalls

> [!WARNING]
> - **Trusting a `~/.bashrc` limit.** Cron jobs, `ssh host cmd` and many systemd sessions never read it.
> - **Setting only a `soft` limit.** A user can raise their own soft limit up to the hard one. The real backstop is `hard`.
> - **Trusting the number in the dotfile.** Read the live value with `ulimit` or `prlimit` first.
