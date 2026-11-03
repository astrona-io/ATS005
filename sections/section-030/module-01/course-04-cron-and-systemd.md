# The Sessions That See None Of This

Astronaut, not every crew member comes aboard through an airlock. Scheduled jobs and ship services are started by the ship itself. This part shows you what cron jobs and systemd services really get in their briefing pack, and how to give them a variable they need.

## Two sessions outside the profile world

Two very common kinds of session do not read the shell profile files at all: **cron** jobs and **systemd** services. Knowing which component starts them tells you what they will see.

### See what cron and systemd really get

Start the probe service, look for both variables in what it recorded, wait for the cron job to run once, and look in its file:

<!-- astrona:playground:renew -->

```sh
sudo systemctl start env-probe.service
grep -E 'COMPANY_PROXY|TEAM_REGION' /run/env-probe.txt || echo "systemd: neither variable"
sleep 61
grep -E 'COMPANY_PROXY|TEAM_REGION' /home/candidate/cron-env.txt || echo "cron: neither variable"
```

Expect something like:

```text
systemd: neither variable
COMPANY_PROXY=http://proxy.internal:3128
```

This assumes `COMPANY_PROXY` is in `/etc/environment` and `TEAM_REGION` is in `/etc/profile.d/team-region.sh`. The systemd unit got neither: it sits outside both PAM and the shell profiles. The cron job (on this Ubuntu image) shows `COMPANY_PROXY` from `/etc/environment`, through cron's own PAM stack, but **not** `TEAM_REGION` from `/etc/profile.d/`. Cron never sources a profile script. That gap is exactly the boundary between the two mechanisms.

### Cron jobs

A cron job does not start a login shell and does not source `/etc/profile`, `~/.bash_profile` or `~/.bashrc`. The cron daemon gives it a small environment, usually just `SHELL`, `PATH`, `HOME` and `LOGNAME`.

On Debian and Ubuntu, cron's PAM stack *does* read `/etc/environment`, so a variable set there may appear in a cron job on this machine. That is specific to these distributions and not true everywhere, so do not rely on it. A scheduled job that needs a variable should have it set directly in the crontab.

### systemd services

A systemd service is started directly by systemd, the ship's duty officer. There is no login shell, and no `pam_env.so` unless that service's PAM stack is set up specially, which is rare. A unit that needs a variable gets it from `Environment=` or `EnvironmentFile=` in the unit file.

## Common pitfalls

> [!WARNING]
> - **Expecting a cron job or systemd unit to inherit a profile variable.** Give it the variable directly: a line in the crontab, or `Environment=` or `EnvironmentFile=` in the unit.
> - **Trusting cron to read `/etc/environment` everywhere.** It does on Debian and Ubuntu through PAM, but that is not universal.
> - **Testing a job's environment from your own shell.** Your shell read your profiles; the job did not. Record the job's own environment, as the probes here do.
