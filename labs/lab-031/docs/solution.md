# Solution Walkthrough

## Step 1: Set the system-wide variable via /etc/environment

The requirement spans *both* login and non-login interactive shells, system-wide, without touching any dotfile. `/etc/environment` is parsed by PAM (`pam_env.so`) at session-establishment time, independent of which shell startup file (if any) runs afterward — so it's the one mechanism that reaches both shell types uniformly.

```bash
sudo tee -a /etc/environment <<'EOF'
COMPANY_PROXY=http://proxy.internal:3128
EOF
```

Note there is no `export` keyword and no quoting needed — `/etc/environment` is parsed, not executed, and understands only bare `KEY=VALUE` lines.

`/etc/profile.d/*.sh` would have been the wrong primary choice here: it's only sourced by `/etc/profile`, which is read for **login shells only** — a non-login interactive shell (a new terminal tab in an already-authenticated session) never touches it.

## Step 2: Verify the system-wide variable from a fresh session

```bash
su - candidate
env | grep COMPANY_PROXY
exit
```

`/etc/environment` is read once at session start — an already-open shell predating the edit will never pick it up. Always test from a genuinely fresh session.

## Step 3: Set the personal variable for candidate only

```bash
su - candidate
echo 'export EDITOR=vim' >> ~/.bash_profile
```

This touches only `candidate`'s own `~/.bash_profile` — no other account and no system-wide file is involved. `export` is required here because, unlike `/etc/environment`, `.bash_profile` is a real shell script that's sourced, not parsed.

## Step 4: Reload and confirm

```bash
source ~/.bash_profile
echo "$EDITOR"
```

## Step 5: Confirm no other account was touched

```bash
grep -rl EDITOR /home/*/.bash_profile /home/*/.bash_login /home/*/.profile /root/.bash_profile 2>/dev/null
```

Expected: only `candidate`'s file appears.

## Verification

```bash
su - candidate -c 'env | grep -E "COMPANY_PROXY|EDITOR"'
```

Expected: both `COMPANY_PROXY=http://proxy.internal:3128` and `EDITOR=vim` present in a fresh login session for `candidate`.

```bash
grep -rn COMPANY_PROXY /home/*/.bashrc /home/*/.bash_profile /home/*/.profile 2>/dev/null
```

Expected: no matches — confirms the system-wide variable was never duplicated into a per-user dotfile.

Once verified, run the local validation suite to pass the lab!
