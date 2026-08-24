# Lab 043: SSSD LDAP Client Integration Sandbox

Welcome to the Module 3 targeted practice sandbox. This lab starts you with a working, populated, TLS-enabled OpenLDAP server (the end state of Modules 1-2) already running on this same host, along with `sssd` and its supporting NSS/PAM modules already installed. You will write `sssd.conf`, wire `nsswitch.conf`, and verify that the LDAP user resolves via NSS before ever testing a login.

## Launching the Lab
Run the following command in your terminal to boot the QEMU VM:
```bash
astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-043
```
