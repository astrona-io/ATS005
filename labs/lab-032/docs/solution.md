# Solution Walkthrough

## Step 1: Confirm the current PATH and where commands resolve from

```bash
su - candidate
echo $PATH
type ls
```

## Step 2: Persist PATH the safe way — append, in a login-shell dotfile

```bash
echo 'export PATH="$PATH:$HOME/work"' >> ~/.bash_profile
```

Appending (`$PATH:$HOME/work`, existing value first) means every existing system directory is searched before `~/work`, so nothing already resolvable elsewhere gets shadowed. `~/.bash_profile` is read for login shells — a fresh terminal session or SSH login — which is what "survives new login shells" requires; `~/.bashrc` alone is not guaranteed to fire for every way a session might start.

## Step 3: Apply it to the current shell and verify

```bash
source ~/.bash_profile
echo $PATH
helper-tool
```

Expected: `helper-tool from ~/work`.

## Step 4: Prove it does NOT shadow an existing command

```bash
cat > ~/work/ls << 'EOF'
#!/bin/bash
echo "decoy ls - should never run"
EOF
chmod +x ~/work/ls
hash -r
type ls
ls
```

`hash -r` clears bash's cached command-location table, forcing a fresh `PATH` search. `type ls` should still report the real system binary (`/bin/ls` or `/usr/bin/ls`), because every system directory in `PATH` comes before `~/work`.

```bash
rm ~/work/ls   # clean up the decoy
```

## Verification

```bash
grep work ~/.bash_profile
# expect: the export PATH line, with $PATH before $HOME/work

echo $PATH | tr ':' '\n'
# expect: /home/candidate/work near/at the end, after the standard system directories

helper-tool
# expect: "helper-tool from ~/work"
```

Once verified, run the local validation suite to pass the lab!
