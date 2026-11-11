# LDAP Directory Population & TLS Bind Verification

Astronaut, your fleet registry is installed, named `dc=example,dc=com` and sealed with TLS, but every drawer is empty. An empty registry helps no one. This module writes real structure into it with LDIF: two drawers (organizational units), a POSIX group and a full POSIX user. Then you set the user's password.

Finally, you prove two separate things: that the user's card is *searchable*, and that a bind as that user succeeds, and succeeds only over an encrypted channel. The POSIX attributes you write here (`uidNumber`, `gidNumber`, `homeDirectory`, `loginShell`) are exactly what a Linux client later reads back to build a login.

## Learning objectives

After this module you can:

- Write a valid LDIF entry (`dn`, `objectClass` and the required attributes), and explain what a blank line separates.
- Explain why parent entries must exist before child entries, and add the `ou=` containers first.
- Tell a structural object class from an auxiliary one, and explain why `posixAccount` needs `inetOrgPerson` beside it.
- Add a POSIX group and a POSIX user with `ldapadd` as the administrator.
- Set a directory password with `ldappasswd` or a pre-hashed `userPassword`, without writing plaintext to a file.
- Prove an entry is searchable, and separately prove a bind as that user succeeds over required TLS, with `-ZZ` and `ldapwhoami`.

## Before you start

Check that you have the knowledge and the playground this module expects before you begin.

### What you should already know

- **A DN** (distinguished name) is the full, path-like address of one entry in the registry, read from right to left.
- **StartTLS** upgrades a plain port 389 connection to an encrypted one; `-ZZ` makes a tool require it.
- **This module changes directory data, not server configuration.** You work with an ordinary authenticated bind as the administrator, not over the `ldapi:///` socket.

### The tools you will use

The commands are the `ldap*` family. Each is named `ldap` plus its operation, and all share the same connection options: `-H` the host address, `-x` a simple bind, `-D` the bind DN, `-W` ask for the bind password (`-w` takes it on the command line), `-b` the search base, and `-Z` or `-ZZ` for StartTLS. This module uses `ldapadd` (create entries), `ldappasswd` (set a password), `ldapsearch` (read entries back) and `ldapwhoami` (report who a bind authenticated as).

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine, with the registry server already set up for you:

- A TLS-secured OpenLDAP server serving **`dc=example,dc=com`**, listening on `389` (StartTLS) and `636` (LDAPS).
- The administrator bind DN **`cn=admin,dc=example,dc=com`**, password **`LdapRoot!2024`**.
- The server's certificate at `/etc/ldap/certs/ldap-server.crt`.
- An **empty** directory: no `ou=`, no groups, no users.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

Open a terminal on it:

```sh
astrona ssh ldap-populate-playground
```

Every command block in the parts runs **inside that virtual machine**.

## How this module is laid out

1. [LDIF And The First Drawers](./course-01-ldif-and-the-first-drawers.md): the LDIF format, and adding `ou=people` and `ou=groups`.
2. [The Group And The User](./course-02-the-group-and-the-user.md): structural and auxiliary object classes, a `posixGroup` and a full POSIX user.
3. [Setting The Password And Proving The Bind](./course-03-setting-the-password-and-proving-the-bind.md): `ldappasswd`, `-ZZ` and `ldapwhoami`.
   - Mission: [LDAP Directory Population & Verified TLS Bind Lab](../../../labs/lab-042/docs/question.md)
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md)

## Why this matters

A Linux client maps these POSIX attributes straight onto a `passwd`-style record. A wrong `homeDirectory` or a missing `loginShell` here becomes a broken login on every ship that uses the registry.

An entry that exists is not the same as an entry someone can bind as over an encrypted channel. The exam, and real life, need both.

> *An entry existing and an entry being reachable over an encrypted bind are two different claims: prove both before you call the directory ready.*

<!-- curriculum-practice -->
## Practice and assessment

- [LDAP Directory Population & Verified TLS Bind Lab](../../../labs/lab-042/docs/question.md): Add organizational units, a POSIX group and a POSIX user from LDIF files; Set the user's password and prove an authenticated bind over required StartTLS.
- [Centralized Identity with LDAP Capstone Lab](../../../labs/lab-040/docs/question.md): Build a TLS-secured OpenLDAP server and populate it with a POSIX group and user; Wire the same host into the directory with sssd and nsswitch; Prove that directory users resolve while local accounts stay unaffected.
