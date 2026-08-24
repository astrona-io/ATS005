# Solution Walkthrough

---

## Part 1: Scoped ACL access on /srv/data/atlas

### Step 1: Inspect the baseline

```bash
ls -ld /srv/data/atlas
getfacl /srv/data/atlas
```

### Step 2: Grant vendor-lee read-write, recursively

```bash
sudo setfacl -R -m u:vendor-lee:rwx /srv/data/atlas
```

### Step 3: Grant qa-nina read-only, recursively

```bash
sudo setfacl -R -m u:qa-nina:rx /srv/data/atlas
```

### Step 4: Set default ACLs for future inheritance

```bash
sudo setfacl -d -m u:vendor-lee:rwx /srv/data/atlas
sudo setfacl -d -m u:qa-nina:rx /srv/data/atlas
```

### Step 5: Verify

```bash
getfacl /srv/data/atlas
ls -ld /srv/data/atlas   # owner/group/mode unchanged, trailing + present
```

---

## Part 2: Proper hard nproc limit for derek

### Step 1: Find the current soft limit

```bash
sudo grep -n ulimit /home/derek/.bashrc
sudo -u derek -i ulimit -Sp
```

### Step 2: Set the hard limit via limits.d

```bash
sudo vi /etc/security/limits.d/derek-nproc.conf
```

```text
derek hard nproc <value-from-step-1>
```

### Step 3: Remove the old .bashrc hack

```bash
sudo sed -i '/ulimit -Sp/d' /home/derek/.bashrc
```

---

## Part 3: supportstaff maxlogins

```bash
getent group supportstaff
sudo vi /etc/security/limits.d/supportstaff-maxlogins.conf
```

```text
@supportstaff hard maxlogins 1
```

---

## Verification

```bash
getfacl /srv/data/atlas
sudo -u vendor-lee touch /srv/data/atlas/probe.txt && getfacl /srv/data/atlas/probe.txt
sudo grep nproc /etc/security/limits.d/derek-nproc.conf
sudo grep ulimit /home/derek/.bashrc   # expect no output
sudo grep maxlogins /etc/security/limits.d/supportstaff-maxlogins.conf
```

Once verified, run the local validation suite to pass the lab!
