# Solution Walkthrough

---

## Step 1: Inspect the current .bashrc hack

```bash
sudo grep -n ulimit /home/jackie/.bashrc
```

Note the number the coworker used (e.g. `ulimit -Sp 175`).

---

## Step 2: Find the currently effective soft limit

```bash
sudo -u jackie -i ulimit -Sp
```

This opens an interactive login shell as jackie and reports the real, currently-active soft `nproc` value — this is the number to reuse as the hard limit.

---

## Step 3: Set the hard nproc limit via a limits.d drop-in

```bash
sudo vi /etc/security/limits.d/jackie-nproc.conf
```

Add (using the number discovered in Step 2):

```text
jackie hard nproc 175
```

A drop-in under `/etc/security/limits.d/` keeps this isolated and easy to review, rather than editing the shared `/etc/security/limits.conf` directly.

---

## Step 4: Remove the old .bashrc hack

```bash
sudo sed -i '/ulimit -Sp/d' /home/jackie/.bashrc
```

The proper `limits.conf` entry now enforces the restriction at session-open time via PAM, regardless of shell type — the `.bashrc` line is redundant and, if left in place, could conflict with the new value.

---

## Step 5: Confirm pam_limits.so is wired into the login path

```bash
grep -n pam_limits /etc/pam.d/common-session /etc/pam.d/login /etc/pam.d/sshd 2>/dev/null
```

Expect a line like `session required pam_limits.so` somewhere in the chain. Without it, the `limits.conf` entry is configured but never enforced.

---

## Step 6: Set the group-wide maxlogins restriction

```bash
getent group operators
sudo vi /etc/security/limits.d/operators-maxlogins.conf
```

Add:

```text
@operators hard maxlogins 1
```

---

## Step 7: Verify

```bash
sudo grep nproc /etc/security/limits.d/jackie-nproc.conf
sudo grep ulimit /home/jackie/.bashrc   # expect no output
sudo -u jackie -i bash -c 'ulimit -Hp; ulimit -Sp'
sudo grep maxlogins /etc/security/limits.d/operators-maxlogins.conf
```

Once verified, run the local validation suite to pass the lab!
