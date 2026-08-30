# LDAP Directory Population & TLS Bind Verification

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS005/tree/main/sections/section-040/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-040/module-02/playground
> astrona destroy ldap-populate-playground
> ```

Module 1 left a server that is installed, TLS-capable, and completely empty. An empty directory helps no one. This module writes real structure into it — organizational units, a POSIX group, a full POSIX user — with LDIF, sets the user's password, and then proves, separately, that the entry is both *searchable* and *bindable*, and that the bind only succeeds over an encrypted connection. The same `posixAccount` attributes written here — `uidNumber`, `gidNumber`, `homeDirectory`, `loginShell` — are exactly what Module 3's `sssd` client reads back out.

> *An entry existing and an entry being reachable over an encrypted bind are two different claims — prove both before calling identity integration done.*

## Learning objectives

After this module you can:

- Write a valid LDIF entry (`dn` + `objectClass` + required attributes) and explain what a blank line separates.
- Explain why parent entries must exist before child entries, and add `ou=` containers first.
- Distinguish a structural object class from an auxiliary one, and explain why `posixAccount` needs `inetOrgPerson` alongside it.
- Add a POSIX group and a POSIX user with `ldapadd` as the admin bind identity.
- Set a directory password with `ldappasswd` or a pre-hashed `userPassword`, without writing plaintext to a file.
- Prove an entry is searchable, and separately prove a bind as that user succeeds only over TLS, using `-ZZ` and `ldapwhoami`.

## Before you start

You should have Module 1's concepts: a **DN** is a unique path-like name for an entry, and StartTLS (`-ZZ`) upgrades a port-389 connection to encrypted. Unlike Module 1, nothing here touches `cn=config` — this is *directory data*, changed with an ordinary authenticated bind as the admin identity, not the `ldapi:///` socket.

The playground VM already has Module 1's finished state, provisioned for you:

- A TLS-secured OpenLDAP server serving **`dc=example,dc=com`**, listening on `389` (StartTLS) and `636` (LDAPS).
- Admin bind DN **`cn=admin,dc=example,dc=com`**, password **`LdapRoot!2024`**.
- The server's certificate at `/etc/ldap/certs/ldap-server.crt`.
- The directory itself is **empty**.

Open a shell on it with:

```sh
astrona ssh astro-ldap-populate-playground
```

Every command block below runs **inside that VM**.

## Where this fits

Module 1 built the container; this module fills it; Module 3 consumes it. The POSIX attributes you set on the user entry here are not decoration — `sssd` maps them straight onto a `passwd`-style record on the client, so a wrong `homeDirectory` or missing `loginShell` here becomes a broken login there.

## LDIF, the language of directory content

Every change to directory data is expressed in **LDIF** (LDAP Data Interchange Format) — plain text, but with strict rules that produce confusing errors when broken. A minimal entry needs one `dn:` line naming its position, one or more `objectClass:` lines declaring which schema classes govern it, and the attributes those classes require. When a file holds multiple entries, a **blank line** separates them:

```ldif
dn: ou=people,dc=example,dc=com
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=example,dc=com
objectClass: organizationalUnit
ou: groups
```

`organizationalUnit` is the standard structural class for a directory "folder." Note that `ou: people` appears both in the `dn:` (as the **RDN** — the relative distinguished name, the leftmost component) and again as its own attribute line. That repetition is required, not redundant — the parser treats the RDN and the attribute as different things.

Apply it as the admin identity Module 1 configured. `ldapadd` is `ldapmodify` with an implicit "add"; `-x` selects simple auth (bind DN + password) rather than SASL; `-W` prompts for the password instead of leaving it in shell history or `ps` output; `-D` names the binding identity.

```sh
ldapadd -x -W -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f /tmp/ou-structure.ldif
```

> [!TIP]
> **Try it — add the two containers**
>
> ```sh
> printf 'dn: ou=people,dc=example,dc=com\nobjectClass: organizationalUnit\nou: people\n\ndn: ou=groups,dc=example,dc=com\nobjectClass: organizationalUnit\nou: groups\n' > /tmp/ou-structure.ldif
> ldapadd -x -W -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f /tmp/ou-structure.ldif
> ```
>
> Enter `LdapRoot!2024` at the prompt. Expect something like:
>
> ```text
> Enter LDAP Password:
> adding new entry "ou=people,dc=example,dc=com"
> adding new entry "ou=groups,dc=example,dc=com"
> ```
>
> Two `adding new entry` lines — the blank line in the file told `ldapadd` these were two separate entries. Remove that blank line and it tries to parse both stanzas as one and rejects the whole file.

## Structural vs. auxiliary object classes

LDAP has a rule with no filesystem equivalent: **a parent entry must exist before any child can be created under it** — there is no `mkdir -p`. `ou=people` and `ou=groups` exist so the group and user below can be placed at all.

Object classes come in two kinds. A **structural** class (like `organizationalUnit`, or `inetOrgPerson` for a person) provides an entry's backbone; every entry must have exactly one. An **auxiliary** class adds attributes but no backbone. `posixAccount` is auxiliary: it supplies `uidNumber`, `gidNumber`, `homeDirectory`, `loginShell`, but cannot stand alone. An entry with `posixAccount` and nothing structural is invalid — one of the most common first-POSIX-user mistakes.

> [!TIP]
> **Try it — watch a structure-less entry get rejected**
>
> ```sh
> printf 'dn: uid=broken,ou=people,dc=example,dc=com\nobjectClass: posixAccount\nuid: broken\ncn: broken\nuidNumber: 12345\ngidNumber: 5000\nhomeDirectory: /home/broken\n' > /tmp/broken.ldif
> ldapadd -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f /tmp/broken.ldif
> ```
>
> Expect something like:
>
> ```text
> adding new entry "uid=broken,ou=people,dc=example,dc=com"
> ldap_add: Object class violation (65)
>         additional info: no structural object class provided
> ```
>
> `posixAccount` alone is not enough — the server refuses the entry. (`-w '<pw>'` passes the password inline; fine in a throwaway playground, but `-W` to be prompted is the habit for a real box.)

The real user entry fixes this by carrying `inetOrgPerson` (structural — supplies `cn`/`sn`) and `shadowAccount` (auxiliary — shadow-style aging attributes) alongside `posixAccount`. A `posixGroup`, by contrast, needs only `cn` and `gidNumber` — it is genuinely complete on its own.

```ldif
dn: cn=developers,ou=groups,dc=example,dc=com
objectClass: posixGroup
cn: developers
gidNumber: 5000

dn: uid=lfcsuser,ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: LFCS User
sn: User
uid: lfcsuser
uidNumber: 10001
gidNumber: 5000
homeDirectory: /home/lfcsuser
loginShell: /bin/bash
```

> [!TIP]
> **Try it — add the group and the user, then read them back**
>
> ```sh
> printf 'dn: cn=developers,ou=groups,dc=example,dc=com\nobjectClass: posixGroup\ncn: developers\ngidNumber: 5000\n\ndn: uid=lfcsuser,ou=people,dc=example,dc=com\nobjectClass: inetOrgPerson\nobjectClass: posixAccount\nobjectClass: shadowAccount\ncn: LFCS User\nsn: User\nuid: lfcsuser\nuidNumber: 10001\ngidNumber: 5000\nhomeDirectory: /home/lfcsuser\nloginShell: /bin/bash\n' > /tmp/lfcsuser.ldif
> ldapadd -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f /tmp/lfcsuser.ldif
> ldapsearch -x -H ldap://127.0.0.1 -b "dc=example,dc=com" -LLL "(uid=lfcsuser)" uidNumber gidNumber homeDirectory loginShell
> ```
>
> Expect something like:
>
> ```text
> adding new entry "cn=developers,ou=groups,dc=example,dc=com"
> adding new entry "uid=lfcsuser,ou=people,dc=example,dc=com"
> dn: uid=lfcsuser,ou=people,dc=example,dc=com
> uidNumber: 10001
> gidNumber: 5000
> homeDirectory: /home/lfcsuser
> loginShell: /bin/bash
> ```
>
> Both entries add cleanly with three `objectClass` lines on the user. The search shows the POSIX attributes stored and readable — the raw material Module 3 turns into a `passwd` entry.

## Setting a password, two ways

The user LDIF has no `userPassword`. Two legitimate ways to add one:

**Live and interactive** — `ldappasswd` against the existing entry:

```sh
ldappasswd -x -W -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -S "uid=lfcsuser,ou=people,dc=example,dc=com"
```

`-S` prompts for the *new* password for the target DN (a separate prompt from `-W`'s admin bind password). This runs the LDAP Password Modify extended operation live; the plaintext is typed only at that prompt.

**Offline and pre-computed** — `slappasswd` produces a hash, which goes straight into the entry's LDIF as a `userPassword:` line at creation time. This is what scripted, non-interactive provisioning uses — no live connection needed when the hash is generated. Either way, a working hashed password ends up in the directory and no plaintext is left in a file.

> [!TIP]
> **Try it — set the password, confirm it took**
>
> ```sh
> ldappasswd -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -s 'LfcsLdap!2024' "uid=lfcsuser,ou=people,dc=example,dc=com"
> ldapsearch -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -b "uid=lfcsuser,ou=people,dc=example,dc=com" -LLL userPassword
> ```
>
> Expect something like:
>
> ```text
> dn: uid=lfcsuser,ou=people,dc=example,dc=com
> userPassword:: e1NTSEF9...redacted...
> ```
>
> (`-s '<newpw>'` supplies the new password inline for the playground; use `-S` to be prompted on a real host.) The `userPassword` attribute now exists, stored as a `{SSHA}` hash — the `::` and base64 are just how `ldapsearch` prints a non-ASCII value.

## Two claims, two proofs

An entry *existing* and a bind *succeeding* are different claims, and different commands prove each.

A plain anonymous search confirms the entry is there and readable — nothing about encryption:

```sh
ldapsearch -x -H ldap://127.0.0.1 -b "dc=example,dc=com" "(uid=lfcsuser)"
```

Adding `-ZZ` requires the StartTLS upgrade to succeed first. The distinction between `-Z` and `-ZZ` matters: a single `-Z` *attempts* StartTLS but silently falls back to plaintext if it fails, so success tells you nothing; `-ZZ` *requires* it and aborts with an error otherwise. To *prove* encryption, `-ZZ` is the only one that does.

Even a successful `-ZZ` search only proves the entry is readable over TLS — not that `lfcsuser`'s own password is right, because that search ran anonymously or as admin. Proving the *credential* needs a bind as that user. `ldapwhoami` performs the "Who am I?" extended operation: no result set to misread, it returns exactly the identity the server tied to the bind, or an explicit failure.

```sh
ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -W -ZZ -H ldap://127.0.0.1
```

> [!TIP]
> **Try it — search proof, then bind proof**
>
> ```sh
> ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "dc=example,dc=com" -LLL "(uid=lfcsuser)" dn
> ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -w 'LfcsLdap!2024' -ZZ -H ldap://127.0.0.1
> ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -w 'wrong-password' -ZZ -H ldap://127.0.0.1
> ```
>
> Expect something like:
>
> ```text
> dn: uid=lfcsuser,ou=people,dc=example,dc=com
> dn:uid=lfcsuser,ou=people,dc=example,dc=com
> ldap_bind: Invalid credentials (49)
> ```
>
> The `-ZZ` search finds the entry over an enforced-encrypted channel. The first `ldapwhoami` binds *as* `lfcsuser` over TLS and the server echoes the DN back — one command proving entry exists + password correct + channel encrypted. The wrong-password attempt fails with `Invalid credentials (49)`, which is what a real bind check looks like when it should fail.

> [!WARNING]
> **Common pitfalls — populating a directory**
>
> - Missing blank line between LDIF entries — `ldapadd` parses them as one malformed entry and rejects the file. It reads as a content error but is a formatting one.
> - `posixAccount` with no structural class — `Object class violation (65)`, "no structural object class provided". Add `inetOrgPerson`.
> - Adding a child before its parent `ou=` exists — fails; there is no implicit parent creation.
> - Password on the command line with `-w` on a real host — visible in `ps` and shell history. Use `-W` / `-S` to be prompted.
> - Trusting a `-Z` result — it may have fallen back to plaintext. Use `-ZZ` when the point is to prove TLS.
> - Concluding a search proves the password — it proves the entry is readable under whoever ran the search. Only `ldapwhoami` (or a real bind) as that user proves the credential.
