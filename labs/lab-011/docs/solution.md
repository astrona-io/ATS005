# Solution Walkthrough

## Step 1: Inspect the current state

```bash
id user1
getent passwd user1
```

Note `user1`'s current primary group and home directory before changing anything.

## Step 2: Create the dev and op groups

```bash
sudo groupadd dev 2>/dev/null
sudo groupadd op 2>/dev/null
```

`dev` must exist before it can be set as `user1`'s primary group; `op` is needed for `user2`'s supplementary groups. `groupadd` exits non-zero if the group already exists — harmless here.

## Step 3: Make sure the parent directory exists

```bash
sudo mkdir -p /home/accounts
```

`usermod -m -d` creates the target leaf directory, but not missing parent directories.

## Step 4: Relocate user1

```bash
sudo usermod -g dev -d /home/accounts/user1 -m user1
```

- `-g dev` sets the new primary group.
- `-d /home/accounts/user1` updates the home directory field.
- `-m` actually moves the old home directory's contents to the new path. Without it, only the passwd record would change.

If this fails with a "currently used by process" error, `user1` has an active session — end it (`sudo pkill -u user1`, with caution) and retry.

## Step 5: Create user2

```bash
sudo useradd -m -d /home/accounts/user2 -G dev,op -s /bin/bash user2
```

Because this is a brand-new account, `-G` isn't replacing anything — there's no prior list to protect. That risk only applies to `usermod -G` on an existing user.

## Step 6: Determine the exact command form to authorize

```bash
which bash
```

Note the resolved path (typically `/usr/bin/bash`).

## Step 7: Write the scoped sudoers rule

```bash
sudo visudo -f /etc/sudoers.d/user2-dangerous-script
```

Add exactly:

```
user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh
```

Adjust the bash path if `which bash` reported something different. This authorizes only that exact command and argument — not a blanket grant.

## Step 8: Lock down permissions and validate

```bash
sudo chmod 0440 /etc/sudoers.d/user2-dangerous-script
sudo chown root:root /etc/sudoers.d/user2-dangerous-script
sudo visudo -c
```

## Verification

```bash
id user1
# gid= should show dev

getent passwd user1
# home directory field should show /home/accounts/user1

ls /home/accounts/user1
# user1's original files should be present

id user2
# groups= should include both dev and op

sudo -l -U user2
# should list the exact NOPASSWD command

su - user2 -c "sudo -n bash /root/dangerous.sh"
# should run with no password prompt
```

## Command Summary

```bash
sudo groupadd dev 2>/dev/null
sudo groupadd op 2>/dev/null
sudo mkdir -p /home/accounts

sudo usermod -g dev -d /home/accounts/user1 -m user1
sudo useradd -m -d /home/accounts/user2 -G dev,op -s /bin/bash user2

which bash
sudo visudo -f /etc/sudoers.d/user2-dangerous-script
# add: user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh

sudo chmod 0440 /etc/sudoers.d/user2-dangerous-script
sudo chown root:root /etc/sudoers.d/user2-dangerous-script
sudo visudo -c

id user1
getent passwd user1
ls /home/accounts/user1
id user2
sudo -l -U user2
su - user2 -c "sudo -n bash /root/dangerous.sh"
```
