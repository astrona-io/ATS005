# Solution Walkthrough

## Part 1: Relocate analyst9

```bash
sudo groupadd -f finance
sudo mkdir -p /home/accounts
sudo usermod -g finance -d /home/accounts/analyst9 -m analyst9
```

`-m` is what actually moves the old home directory's contents — `-d` alone only rewrites the passwd pointer.

## Part 2: Provision newhire9 with scoped sudo

```bash
sudo groupadd -f ops
sudo useradd -m -d /home/accounts/newhire9 -G finance,ops -s /bin/bash newhire9

which bash
sudo visudo -f /etc/sudoers.d/newhire9-rotate-logs
# add: newhire9 ALL=(root) NOPASSWD: /usr/bin/bash /root/rotate-logs.sh

sudo chmod 0440 /etc/sudoers.d/newhire9-rotate-logs
sudo chown root:root /etc/sudoers.d/newhire9-rotate-logs
sudo visudo -c
```

Adjust the bash path to whatever `which bash` reports. The rule must name the exact command including the `bash` invocation, since that's how the task specifies it's run.

## Part 3: Group lifecycle

```bash
sudo groupadd -g 6000 billing-team
sudo usermod -aG billing-team analyst9
sudo usermod -aG billing-team newhire9

getent group legacy-billing
sudo groupmod -n archive-billing legacy-billing
getent group archive-billing

sudo groupdel temp-scratch
```

`-aG` (append) is required both times — plain `-G` would replace each user's entire supplementary group list. `groupmod -n` renames only, keeping the GID and membership list intact.

## Part 4: Lock audit2

```bash
sudo passwd -l audit2
sudo passwd -S audit2
```

## Part 5: Force shortterm3 to expire in 14 days

```bash
sudo chage -E "$(date -d '+14 days' +%Y-%m-%d)" shortterm3
sudo chage -l shortterm3
```

`-E` sets a hard account-expiration date — distinct from password aging (`-M`), which only governs the current password's lifetime.

## Part 6: Remove leaver5

```bash
sudo userdel -r leaver5
```

## Verification

```bash
id analyst9                     # gid= finance
getent passwd analyst9          # home /home/accounts/analyst9
ls /home/accounts/analyst9      # original files present

id newhire9                     # groups include finance, ops, billing-team
sudo -l -U newhire9             # exact NOPASSWD rule for rotate-logs.sh
su - newhire9 -c "sudo -n bash /root/rotate-logs.sh"

getent group billing-team       # GID 6000, analyst9+newhire9 members
getent group archive-billing    # GID 7000, membership intact
getent group legacy-billing     # no output
getent group temp-scratch       # no output

sudo passwd -S audit2           # L (locked)
sudo chage -l shortterm3        # account expires ~14 days from now

id leaver5                      # no such user
ls /home/leaver5                # No such file or directory
```
