# Login Scripts In /etc/profile.d

Astronaut, the notice board takes only plain lines. When a ship-wide variable needs real shell logic, you write a short script instead. This part shows you `/etc/profile.d/`, the ship-wide briefing read to everyone who comes aboard through the main airlock, and the one door it does not cover.

## When you need a script

Change the requirement to "support real shell syntax, such as a condition or a computed value, ship-wide", and `/etc/environment` cannot do it. A script in `/etc/profile.d/` can.

### Write a profile.d script

Save this as `/etc/profile.d/company-proxy.sh`:

<!-- astrona:playground:renew -->

```bash
export COMPANY_PROXY="http://proxy.internal:3128"
```

Apply it, by making the script readable for every user:

```sh
sudo chmod 644 /etc/profile.d/company-proxy.sh
```

Nothing else needs to run now: the script is read the next time someone logs in.

### Who reads `/etc/profile.d/`

Every `.sh` file in `/etc/profile.d/` is sourced by `/etc/profile`. "Sourced" means the shell runs the file's lines inside itself, so `export`, conditions and other commands all work, as in any script. The catch is in that sentence: `/etc/profile` is read only by **login shells**. That is why `/etc/environment` is the right choice when both kinds of shell must see a variable, and `/etc/profile.d/` is not.

## Login shells only

A `profile.d` variable reaches people who come aboard through the main airlock, and nobody else. You can see the missing door directly.

### Watch a profile.d variable skip the non-login shell

Save this as `/etc/profile.d/team-region.sh`:

```bash
export TEAM_REGION="eu-west"
```

Nothing needs reloading. Then check the result from a login shell and from a non-login shell:

```sh
su - candidate -c 'echo "login: $TEAM_REGION"'
su candidate -c 'echo "non-login: $TEAM_REGION"'
```

Expect something like:

```text
login: eu-west
non-login:
```

The login shell read `/etc/profile`, which sourced the drop-in. The non-login shell never touched `/etc/profile`, so the variable is simply absent. It is not broken; it is never read on that path.

> [!TIP]
> Before you choose a file, ask which door the session uses. "Every login" points to `/etc/profile.d/`; "every session, login or not, plain value" points to `/etc/environment`.

## Common pitfalls

> [!WARNING]
> - **A `profile.d` variable "missing" in a new terminal tab.** That tab is a non-login shell, and `/etc/profile.d/` is read by login shells only. Use `/etc/environment` for both types, or `~/.bashrc` for the interactive case.
> - **A file name without `.sh`.** `/etc/profile` only sources files that end in `.sh`.
> - **Forgetting `export` in the script.** Without it, the variable stays inside the login shell and never reaches the programs it starts.
