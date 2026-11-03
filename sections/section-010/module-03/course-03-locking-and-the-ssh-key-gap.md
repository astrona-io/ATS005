# Locking An Account And The SSH Key Gap

Astronaut, a crew member under investigation must stop coming aboard at once, but their entry and their quarters must stay as they are. This part shows you how to lock an account without deleting anything, how to read its state, and the one gap that a lock does not close.

## Locking and unlocking without deleting

Locking puts a `!` on the door code so it can never match. The crew member stays on the roster, and every setting and file stays in place.

### Lock, and read the status letter

Lock `contractor3`, then ask for its status:

<!-- astrona:playground:renew -->

```sh
sudo passwd -l contractor3
sudo passwd -S contractor3
```

Expect something like:

```text
passwd: password expiry information changed.
contractor3 L 08/30/2026 0 99999 7 -1
```

The `L` in the second field means locked. The password hash is still there under the `!` prefix, so `passwd -u contractor3` would bring the old password straight back.

### How the lock works

`passwd -l` (for **l**ock) puts a prefix, usually `!`, in front of the password hash in `/etc/shadow`, so the stored hash can never match anything typed. It does not clear the hash. Unlocking with `passwd -u` (for **u**nlock) restores the *exact earlier password*, not a blank one. `usermod -L` and `usermod -U` do the same on the `usermod` side.

`passwd -S` (for **S**tatus) reports one short code: `L` for locked, `P` for a usable password, `NP` for no password. It is the fastest way to check the state without reading `/etc/shadow`.

## The SSH key gap

This is the most important warning in the module: **locking the password does nothing to key-based SSH.** The lock lives in the password field, and an SSH key never looks at that field.

### Why a key still gets in

If a locked account already has a key in `~/.ssh/authorized_keys` and `sshd` allows key login, that user still logs in. `passwd -l` never touches that file, and key login does not check the password. A *complete* lockout also removes or renames `authorized_keys`, or takes away the login shell:

```sh
sudo usermod -s /usr/sbin/nologin contractor3
```

`/usr/sbin/nologin` is a real program. It prints a refusal and exits with an error, so the session ends right after login.

### The locked account still lets a key in, until the shell is gone

Check the lock, log in with the key, set the shell to `nologin`, and try again:

```sh
sudo passwd -S contractor3
ssh -i /root/contractor3_key -o StrictHostKeyChecking=no contractor3@localhost id
sudo usermod -s /usr/sbin/nologin contractor3
ssh -i /root/contractor3_key -o StrictHostKeyChecking=no contractor3@localhost id
```

Expect something like:

```text
contractor3 L ...
uid=1001(contractor3) gid=1001(contractor3) groups=1001(contractor3)
This account is currently not available.
```

The password shows `L`, yet the first `ssh` runs `id` as `contractor3`: the key login walked straight past the lock. Only after the shell is `nologin` is the second try refused. The private key is in `/root`, so if `ssh` cannot read it, run these as `root` (for example after `sudo -i`).

> [!TIP]
> For an incident, think in layers: the password (`passwd -l`), the keys (`authorized_keys`), the shell (`nologin`) and the account dates (`chage -E`). Write down which layers you closed.

## Common pitfalls

> [!WARNING]
> - **"`passwd -l` locked the account."** It locked the *password*. Key-based SSH, and anything else that does not check the password field, still works. Deal with the key or the shell for a full lockout.
> - **Deleting the hash to lock an account.** Do not. `passwd -l` keeps the hash on purpose so `passwd -u` can restore the original password. Blanking `/etc/shadow` by hand loses it.
> - **Expecting a lock or `chage -E` to end an open session.** Both are checked at login, not afterwards. End the session separately if the task asks for it.
