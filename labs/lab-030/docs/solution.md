# Solution Walkthrough

## Step 1: System-wide ONBOARD_PORTAL for login shells via /etc/profile.d/

Because this requirement only needs to reach login shells (not non-login interactive ones) and benefits from real shell syntax, `/etc/profile.d/*.sh` is the right tool — unlike `/etc/environment`, its scripts are genuinely sourced by `/etc/profile`.

```bash
sudo tee /etc/profile.d/onboard.sh > /dev/null <<'EOF'
export ONBOARD_PORTAL="https://portal.internal/onboarding"
EOF
sudo chmod 644 /etc/profile.d/onboard.sh
```

## Step 2: Verify from a fresh login session

```bash
su - candidate -c 'echo $ONBOARD_PORTAL'
```

Expected: `https://portal.internal/onboarding`.

## Step 3: Personal EDITOR for candidate only

```bash
su - candidate
echo 'export EDITOR=nano' >> ~/.bash_profile
source ~/.bash_profile
echo "$EDITOR"
```

## Step 4: Append ~/bin to candidate's PATH safely

```bash
echo 'export PATH="$PATH:$HOME/bin"' >> ~/.bash_profile
source ~/.bash_profile
deploy-helper
```

Appending keeps every system directory ahead of `~/bin` in the search order, so nothing existing is shadowed.

## Step 5: Prove no shadowing

```bash
cat > ~/bin/id << 'EOF'
#!/bin/bash
echo "decoy id - should never run"
EOF
chmod +x ~/bin/id
hash -r
type id
id
rm ~/bin/id
```

Expected: `type id` still resolves to `/usr/bin/id`, not `~/bin/id`.

## Verification

```bash
su - candidate -c 'env | grep -E "ONBOARD_PORTAL|EDITOR"'
su - candidate -c 'echo $PATH | tr ":" "\n"'
su - candidate -c 'deploy-helper'
```

Once verified, run the local validation suite to pass the lab!
