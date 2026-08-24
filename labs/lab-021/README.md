# Lab 021: ACL-Based Shared Directory Access Lab

Welcome to the Module 1 targeted practice sandbox. In this lab, you will grant two different external users scoped access to a shared project directory entirely via POSIX ACLs, without touching group membership, and make sure new files automatically inherit that access.

## Launching the Lab
Run the following command in your terminal to boot the QEMU VM:
```bash
astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-021
```
