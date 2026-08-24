# lab-040: Centralized Identity with LDAP Capstone

QEMU VM for the LFCS course — the Section 040 capstone. Stand up and secure an OpenLDAP server with TLS, populate it with organizational structure and a real POSIX user, and wire `sssd` on the very same host to resolve and authenticate that user, all in one integrated scenario.

## Run

```bash
astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-040
```
