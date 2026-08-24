# Lab 042: LDAP Directory Population & Verified TLS Bind Sandbox

Welcome to the Module 2 targeted practice sandbox. This lab starts you with a working, empty, TLS-enabled OpenLDAP server (the end state of Module 1). You will populate it with organizational structure and a real POSIX user via LDIF, set a password, and prove that an authenticated bind succeeds only over an encrypted connection.

## Launching the Lab
Run the following command in your terminal to boot the QEMU VM:
```bash
astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-042
```
