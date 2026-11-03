# Solution Walkthrough

This walkthrough switches on home creation and adds a starter file. Run every command on the lab machine (`astrona ssh ats-005-lab-044`).

---

## Step 1: Confirm the problem

```bash
getent passwd newcomer
ls -d /home/newcomer
```

- The user resolves, and the folder does not exist.

---

## Step 2: Add the starter file

```bash
echo "Welcome aboard." | sudo tee /etc/skel/WELCOME.txt
```

- Anything in `/etc/skel` is copied into every home created afterwards.

---

## Step 3: Switch on mkhomedir

```bash
sudo pam-auth-update --enable mkhomedir
grep mkhomedir /etc/pam.d/common-session
```

- The profile adds a `session` line for `pam_mkhomedir.so` to the shared file.

---

## Step 4: Test with a user who never logged in

```bash
sudo su - newcomer -c pwd
ls -A /home/newcomer
```

- `su -` runs the session steps, so the home is created and `WELCOME.txt` is inside.

---

## Step 5: Submit

```bash
astrona submit -c labs/lab-044
```
