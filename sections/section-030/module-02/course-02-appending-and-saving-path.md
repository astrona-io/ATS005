# Appending And Saving PATH

Astronaut, an impostor can only win if its deck is searched before the real crew member's deck. This part shows you how adding your directory to the *end* of `PATH` closes that gap, and how to save the change so it survives every new login.

## Appending closes the gap

Reverse the order, and put the directory last:

```sh
export PATH="$PATH:$HOME/work"
```

Now every system directory is searched first. A really new tool name still works: it is found in `~/work` only because no earlier directory has it. But an existing command name is never overridden, because its real match is found in an earlier directory before the search reaches `~/work`.

### Real command wins, new tool still found

Open a shell as `candidate`, append `~/work`, clear the cache, and look up both names:

<!-- astrona:playground:renew -->

```sh
su - candidate
export PATH="$PATH:$HOME/work"
hash -r
type ls
type helper-tool
helper-tool
exit
```

Expect something like:

```text
ls is aliased to `ls --color=auto'
helper-tool is /home/candidate/work/helper-tool
helper-tool running from ~/work
```

`ls` still resolves ahead of `~/work`; even if a decoy `ls` sits in `~/work`, it is now last in the search order and loses. `helper-tool`, which collides with nothing, resolves in `~/work` and runs. You get both properties at once.

### Why append is the default

Appending adds the convenience without the security risk. It is the right default unless a task explicitly asks for one of your scripts to override a system command.

## Saving it in the right file

A `PATH` change typed into a running shell lasts only as long as that shell. To survive new logins, it must go in a dotfile that a **login shell** reads at startup.

### Which file to use

Use the login-shell file the account really reads *first*. Bash checks `~/.bash_profile`, then `~/.bash_login`, then `~/.profile`, and reads only the first one that exists. A stock Ubuntu account has only `~/.profile`.

`~/.bashrc` alone is not a safe place. It is read for *interactive non-login* shells, and it is not certain to run for every way a session starts. A `PATH` line placed only there can pass a quick test and then "not stick" when the user connects another way.

### The change survives a fresh login

Append the line to `candidate`'s `~/.profile`, then check from a fresh login shell:

```sh
echo 'export PATH="$PATH:$HOME/work"' >> /home/candidate/.profile
su - candidate -c 'type helper-tool; helper-tool'
```

Expect something like:

```text
helper-tool is /home/candidate/work/helper-tool
helper-tool running from ~/work
```

`su - candidate` is a fresh login shell. It read `~/.profile`, which now appends `~/work`, so `helper-tool` resolves by name with no `export` typed in this session.

A shell that was already running keeps its own copy of `PATH` from when it started, and editing a file on disk does nothing to it. You can `source` the file into your current shell to test quickly, but a brand-new session is the stronger proof.

## Common pitfalls

> [!WARNING]
> - **Saving the line in `~/.bashrc` only.** That is the non-login file. Use the account's login-shell file (`~/.profile` on stock Ubuntu) so the change survives every login path.
> - **Writing to a file the shell does not read.** If `~/.bash_profile` exists, a login shell ignores `~/.profile`. Put the line in the first file that exists.
> - **Using `>` instead of `>>`.** A single `>` replaces the whole dotfile with your one line.
> - **Testing in the shell you edited in.** It still holds its old `PATH`. `source` the file or open a new session.
