# Lab 041: OpenLDAP Server Install & TLS Sandbox

Welcome to the Module 1 targeted practice sandbox. In this lab, you will configure a freshly-installed OpenLDAP server via its `cn=config` backend, wire a pre-supplied TLS certificate and key into it, and confirm both StartTLS (389) and native LDAPS (636) are live and working.

## Launching the Lab
Run the following command in your terminal to boot the QEMU VM:
```bash
astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-041
```
