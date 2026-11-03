# The Ship-Wide Notice Board

Astronaut, some facts every crew member must know, whichever door they came aboard through. This part shows you `/etc/environment`, the ship-wide notice board, and why it is a list of plain lines and not a script.

## A file that is not a script

`/etc/environment` holds one variable per line. It looks like a shell script waiting to happen, but no shell ever runs it. That decides what you may write in it.

### Add one line and read it from two kinds of shell

Here is the line you will add:

```text
COMPANY_PROXY=http://proxy.internal:3128
```

Append it to `/etc/environment`, then read the variable from a login shell (`su -`) and from a non-login shell (plain `su`):

<!-- astrona:playground:renew -->

```sh
echo 'COMPANY_PROXY=http://proxy.internal:3128' | sudo tee -a /etc/environment
su - candidate -c 'echo "login: $COMPANY_PROXY"'
su candidate -c 'echo "non-login: $COMPANY_PROXY"'
```

Expect something like:

```text
COMPANY_PROXY=http://proxy.internal:3128
login: http://proxy.internal:3128
non-login: http://proxy.internal:3128
```

The first line is `tee` echoing what it appended. Both `su` forms then show the value. `su -` (login) and plain `su` (non-login) both go through PAM, and `pam_env.so` ran for each. An already-open shell would *not* show it: PAM reads the file once, at session start, and there is no reload.

## Parsed, not run

Every instinct says to add `export` to that line. Do not. The rule behind it is about which component reads the file.

### Who reads `/etc/environment`

`/etc/environment` is **parsed** by a PAM module, `pam_env.so`, when a session is set up, before any shell startup file runs. "Parsed, not run" means it understands exactly one format: a bare `KEY=VALUE` per line, quoted if the value has spaces. There is no `export`, no `$OTHER_VAR` expansion and no command substitution. Write `export FOO=bar` here, and the line does not mean what you wanted.

### Why it reaches both kinds of shell

`pam_env.so` runs at the PAM session layer, not inside a shell's startup sequence. So `/etc/environment` is read for **any** session PAM sets up, login shell or interactive non-login shell alike. It is the one mechanism in this module that ignores that difference. That makes it the right choice when a plain variable must reach both kinds of shell, ship-wide, and the wrong choice the moment you need shell logic.

## Common pitfalls

> [!WARNING]
> - **`export FOO=bar` in `/etc/environment`.** The file is parsed, not run. Write a bare `FOO=bar`; `export` and `$VAR` expansion do nothing there.
> - **Testing in a shell that was already open.** PAM reads `/etc/environment` only when a session starts. Test with a fresh `su -`, `su` or SSH login.
> - **Overwriting the file.** Use `tee -a` (append). Plain `tee` replaces the whole file, including the `PATH` line Ubuntu keeps there.
