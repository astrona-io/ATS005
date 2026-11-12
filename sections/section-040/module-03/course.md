# LDAP Client Integration with SSSD

Astronaut, your fleet registry is running, sealed with TLS, and holds a `developers` group and the user `lfcsuser`. But a registry that no ship reads from is still just a database. This module closes the loop.

You set up the same machine, now acting as a *client*, to treat the registry as its source of truth for who exists and who may log in. The tool is `sssd`, the ship's records officer: it asks the fleet registry and keeps a short-term copy. It is the integration layer that current distributions, and the LFCS (Linux Foundation Certified System Administrator) exam, expect.

## Learning objectives

After this module you can:

- Explain what `sssd` gives you over a direct NSS-to-LDAP setup: a cache, a real daemon, and retries.
- Write `/etc/sssd/sssd.conf` with an `[sssd]` section and a matching `[domain/…]` section for an LDAP backend over StartTLS.
- Explain why `services`, `domains` and the domain header must line up, and what `id_provider` and `auth_provider` mean.
- Set `sssd.conf` to mode `600`, owner `root:root`, and explain why `sssd` refuses to start when it is looser.
- Add `sss` to `/etc/nsswitch.conf` in the right order, and explain why `files` first keeps local accounts safe.
- Check NSS resolution with `getent` and `id` before you try a login, and confirm that `root` still resolves from `files`.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **Services and logs.** `systemctl`, `journalctl`, and editing files under `/etc`.
- **NSS.** NSS (Name Service Switch) turns a user name into a UID, a group name into a GID, and so on. `/etc/nsswitch.conf` is the ship's list of which rosters to ask, and in which order.

### The two checking tools

Two commands do most of the checking:

- `getent` (short for *get entries*) asks NSS for a record exactly the way the system does. `getent passwd lfcsuser` returns the same line a login would use, so it walks the whole `nsswitch.conf` chain, including `sss` once you add it.
- `sssctl` (short for *SSSD control*) is `sssd`'s own administration tool. `sssctl config-check` checks the syntax *and* the file permissions of `sssd.conf` without starting the daemon.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. It already has:

- A TLS-secured LDAP server on `127.0.0.1` serving `dc=example,dc=com`, with `ou=people`, `ou=groups`, a `developers` group (GID `5000`), and `uid=lfcsuser` (UID `10001`, home `/home/lfcsuser`, shell `/bin/bash`, password `LfcsLdap!2024`).
- The server's certificate at `/etc/ldap/certs/ldap-server.crt`.
- The packages `sssd`, `sssd-ldap`, `libnss-sss` and `libpam-sss` **installed but not configured**: no `/etc/sssd/sssd.conf`, `nsswitch.conf` untouched, `sssd` not running.
- `pam_mkhomedir` switched on and SSH password login allowed, so a first login works cleanly.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh sssd-client-playground
```

Every command block in the parts runs **inside that virtual machine**.

## How this module is laid out

1. [Why SSSD](./course-01-why-sssd.md): what `sssd` adds over a direct NSS-to-LDAP setup, and the packages that make it visible.
2. [Writing sssd.conf](./course-02-writing-sssd-conf.md): the `[sssd]` and domain sections, and the permission check `sssd` runs on itself.
3. [Wiring NSS And Checking In Order](./course-03-wiring-nss-and-checking-in-order.md): `sss` in `nsswitch.conf`, then resolution, login and `root`.
   - Mission: [SSSD LDAP Client Integration Lab](../../../labs/lab-043/docs/question.md)
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md)

## Why this matters

This is the end of the chain: the client reads the POSIX attributes stored in the registry and turns them into users the ship knows. Get it wrong, and nobody from the registry can log in.

The habit this module teaches applies to every PAM or NSS change, LDAP or not: never make a change that could break local login without a proven way back.

> *Prove NSS resolution with `getent` and `id` before you ever test a login: an authentication change that also breaks local accounts can lock you out completely.*

<!-- curriculum-practice -->
## Practice and assessment

- [SSSD LDAP Client Integration Lab](../../../labs/lab-043/docs/question.md): Write a secure sssd.conf that reaches the directory over StartTLS; Add sss to nsswitch.conf and resolve directory users and groups with getent; Prove that local accounts still resolve as before.
- [Centralized Identity with LDAP Capstone Lab](../../../labs/lab-040/docs/question.md): Build a TLS-secured OpenLDAP server and populate it with a POSIX group and user; Wire the same host into the directory with sssd and nsswitch; Prove that directory users resolve while local accounts stay unaffected.
