# Overview: PLAYGROUND — LDAP Client Integration with SSSD

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A qemu Ubuntu 24.04 VM, reached with `astrona ssh astro-sssd-client-playground`.
- Modules 1-2's finished state: a TLS-secured OpenLDAP server on `127.0.0.1`
  serving `dc=example,dc=com`, containing `ou=people`, `ou=groups`, a
  `developers` group (GID `5000`), and `uid=lfcsuser` (UID `10001`, home
  `/home/lfcsuser`, shell `/bin/bash`, password **`LfcsLdap!2024`**).
- The server's certificate at `/etc/ldap/certs/ldap-server.crt`.
- Packages `sssd`, `sssd-ldap`, `libnss-sss`, `libpam-sss` installed but
  **unconfigured** — no `/etc/sssd/sssd.conf`, `nsswitch.conf` untouched, `sssd`
  not running.
- `pam_mkhomedir` enabled, so a first login creates the home directory.
- SSH password authentication is enabled, so `ssh lfcsuser@127.0.0.1` can be
  used to test the LDAP-backed login.

## Things to try

- `getent passwd lfcsuser` now — returns nothing. Note why before changing
  anything.
- Write `/etc/sssd/sssd.conf` with a `[domain/example.com]` pointing at
  `ldap://127.0.0.1`, `ldap_id_use_start_tls = true`, and
  `ldap_tls_cacert = /etc/ldap/certs/ldap-server.crt`.
- `chmod 600` / `chown root:root` the file, then `systemctl enable --now sssd`
  and read `journalctl -u sssd`.
- Add `sss` to the `passwd` and `group` lines of `/etc/nsswitch.conf`.
- Verify in order: `getent passwd lfcsuser`, `id lfcsuser`, then
  `ssh lfcsuser@127.0.0.1`, then `getent passwd root` / `id root`.
- Try loosening `sssd.conf` to `644` and restarting — watch `sssd` refuse.

## When you're done

```sh
astrona destroy astro-sssd-client-playground
```
