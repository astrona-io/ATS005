# Wiring NSS And Checking In Order

Astronaut, the records officer has orders, but nobody on the ship asks them anything yet. This part shows you how to add `sss` to the ship's list of rosters, and the right order to check your work: resolution first, then a real login, then `root`.

## Telling NSS to actually ask

Nothing so far matters until NSS asks `sssd`. `/etc/nsswitch.conf` lists, for each database, the sources to ask, in order. The `passwd` and `group` lines need `sss` added:

```text
passwd:         files sss
group:          files sss
```

### Why the order is the point

NSS checks sources from left to right. A lookup for `root` is answered by `files` (`/etc/passwd`) before `sss` is ever asked, whether or not `sssd` or the directory is healthy. That is the whole reason a broken LDAP setup does not lock you out. `sss` before `files` would be the dangerous order.

### Wire NSS, start sssd, and resolve the user

Append `sss` to both lines, check them, start `sssd`, and look up the user and the group:

<!-- astrona:playground:renew -->

```sh
sudo sed -i -E '/^(passwd|group):/ s/$/ sss/' /etc/nsswitch.conf
grep -E '^(passwd|group):' /etc/nsswitch.conf
sudo systemctl enable --now sssd
getent passwd lfcsuser
getent group developers
```

Expect something like:

```text
passwd:         files systemd sss
group:          files systemd sss
lfcsuser:*:10001:5000:LFCS User:/home/lfcsuser:/bin/bash
developers:*:5000:
```

With `sss` added after `files` and `sssd` running, `getent passwd lfcsuser` returns a full `passwd`-style line built from the POSIX attributes in the registry. `sssd` asked LDAP over StartTLS, and NSS handed the answer back. Without `sss` on the line, this would still return nothing, however correct `sssd.conf` is.

## Check in order: resolution, then login

There is a right order for testing. Skipping ahead wastes time on the wrong layer, because a failed login cannot tell you whether the lookup or the password check broke.

### The order and why

The three steps:

1. **Resolution, with no password involved:** `getent passwd lfcsuser`, `getent group developers` and `id lfcsuser`. `getent` walks the exact chain in `nsswitch.conf`, so a clean result proves the whole identity path. `id` also checks group membership, which `getent passwd` alone would miss.
2. **Then, and only then, a real login**, from a **second** session, while you keep your privileged one open: `ssh lfcsuser@127.0.0.1`.
3. **Finally, the thing that must never change:** `getent passwd root` and `id root`. `root` resolves from `files` whatever state `sssd` is in. This proves the change only added a source; it did not replace one. Run it again any time you touch PAM or NSS.

### Resolution, a real LDAP login, and root untouched

Run all three steps:

```sh
id lfcsuser
sshpass -p 'LfcsLdap!2024' ssh -o StrictHostKeyChecking=no lfcsuser@127.0.0.1 'whoami; pwd'
getent passwd root
id root
```

Expect something like:

```text
uid=10001(lfcsuser) gid=5000(developers) groups=5000(developers)
lfcsuser
/home/lfcsuser
root:x:0:0:root:/root:/bin/bash
uid=0(root) gid=0(root) groups=0(root)
```

`id lfcsuser` resolves the UID, the GID and the group from LDAP. The `ssh` login checks `lfcsuser`'s password against the directory (PAM, then `sssd`, then an LDAP bind), and `pam_mkhomedir` creates `/home/lfcsuser` on the way in. `root` still resolves from `/etc/passwd`, with `x` in the password field: the local account path is completely unaffected. `sshpass` is only on the playground for a non-interactive demonstration; normally you type the password.

> [!TIP]
> After any PAM or NSS change, run `getent passwd root` and `id root` before you log out of your privileged session. If they fail, fix it while you still have a way in.

## Common pitfalls

> [!WARNING]
> - **`sssd.conf` is perfect, but `getent passwd lfcsuser` is still empty.** Check `/etc/nsswitch.conf` first. No `sss` on the `passwd` line means NSS never asks `sssd`.
> - **`sss` before `files` in `nsswitch.conf`.** A directory outage can now break `root` lookups. Keep `files` first.
> - **Testing a login before `getent` and `id`.** It mixes identity lookup and password checking, so you cannot tell which one failed.
> - **Testing the login in your only privileged session.** Keep one session open, and log in from a second one.

## Your mission: SSSD LDAP Client Integration Lab

You can now write a secure `sssd.conf`, add `sss` to `nsswitch.conf` in the right order, and prove resolution while local accounts stay safe. Now prove it in a graded mission: a fresh ship with a populated registry and the `sssd` packages installed, where you wire the client and check in order.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop sssd-client-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-043
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-043
```

Read the task in [`question.md`](../../../labs/lab-043/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-043
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-043
astrona start sssd-client-playground
```
