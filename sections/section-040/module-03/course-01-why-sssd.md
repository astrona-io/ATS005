# Why SSSD

Astronaut, a ship can ask the fleet registry directly on every lookup, or it can keep a records officer who asks for it. This part shows you why the records officer, `sssd`, is the better choice, which packages connect it to the rest of the ship, and what the ship sees before anything is configured.

## Why SSSD, not direct NSS-to-LDAP

Older systems wired NSS straight to LDAP with modules such as `libnss-ldap`. That asks the directory on *every* lookup, synchronously, with no cache.

### The cost of asking every time

With a direct setup, every `getent` and every login hits the server fresh. A short outage breaks lookups for everyone, including users who logged in five minutes ago.

`sssd` (short for *System Security Services Daemon*) sits between NSS and PAM on one side and the directory on the other, as a real daemon. That gives three things:

- **A local cache.** A short outage does not lock out users the ship has already seen.
- **Connection handling.** It retries and reconnects, instead of one synchronous attempt per lookup.
- **One configuration surface.** It can back onto LDAP, Kerberos or Active Directory without the rest of the system noticing.

### The packages that make it visible

Each package has one job:

- `sssd-ldap` is the LDAP backend provider.
- `libnss-sss` is the NSS module that lets the C library reach the running daemon.
- `libpam-sss` is the PAM module that lets the login checklist (PAM, Pluggable Authentication Modules) reach it.

Without the last two, `sssd` can run perfectly and stay invisible.

## Nothing resolves yet

Before you configure anything, look at the starting point. Installed is not the same as integrated.

### See the packages, and an empty answer

Check the packages, look for a configuration file, and ask for the user:

<!-- astrona:playground:renew -->

```sh
dpkg -l sssd sssd-ldap libnss-sss libpam-sss | grep '^ii'
ls /etc/sssd/sssd.conf 2>&1
getent passwd lfcsuser; echo "exit: $?"
```

Expect something like:

```text
ii  sssd            ...
ii  sssd-ldap       ...
ii  libnss-sss      ...
ii  libpam-sss      ...
ls: cannot access '/etc/sssd/sssd.conf': No such file or directory
exit: 2
```

Every package is installed, yet `getent passwd lfcsuser` returns nothing (exit code `2` means "not found"). There is no configuration, and NSS has not been told to ask `sssd`.

## Common pitfalls

> [!WARNING]
> - **Expecting installed packages to do something.** Without `sssd.conf` and an `sss` entry in `nsswitch.conf`, nothing changes.
> - **Forgetting `libnss-sss` or `libpam-sss`.** `sssd` runs, but lookups or logins never reach it.
> - **Reading exit code `2` as a crash.** For `getent` it simply means "not found".

## Prove authentication with a fresh identity

`getent passwd lfcsuser` proves identity lookup, but an old SSSD cache entry can answer after the directory goes offline. It also says nothing about the password. Test a directory-only identity that has never logged in, then use a PAM authentication client with its correct password and with a deliberately wrong one. Root's `su` can skip password checks, so it is unsuitable evidence.

For this StartTLS exercise, `/etc/sssd/sssd.conf` must set `ldap_id_use_start_tls = true`, `ldap_tls_reqcert = demand`, and `ldap_tls_cacert` to the trusted lab certificate. Keep the file owned by root with mode 600. Restart SSSD after changes and inspect `journalctl -u sssd` when lookup fails.

The lab grader creates and removes a fresh directory probe, then tests lookup and PAM password authentication. CI also configures an unrelated CA and confirms fresh authentication fails. Setting `ldap_tls_reqcert = never` is rejected because it lets an untrusted server impersonate the directory.
