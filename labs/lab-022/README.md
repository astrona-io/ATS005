# Lab 022: PAM Hard Limits & maxlogins Lab

Welcome to the Module 2 targeted practice sandbox. In this lab, you will replace a fragile `.bashrc` ulimit hack with a proper PAM-enforced hard process limit, and cap concurrent logins for a group with `maxlogins`.

## Launching the Lab
Run the following command in your terminal to boot the QEMU VM:
```bash
astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-022
```
