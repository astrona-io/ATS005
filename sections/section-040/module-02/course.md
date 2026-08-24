# Module 2: LDAP Directory Population & TLS Bind Verification

> *A directory entry existing and a directory entry being reachable over an encrypted bind are two different things to verify — prove both before you call identity integration done.*

Module 1 left you with a server that is installed, TLS-capable, and completely empty. An empty directory is not useful to anyone. This module writes real structure into it — organizational units, a POSIX group, a full POSIX user — using LDIF, sets that user's password, and then proves, deliberately and separately, that the resulting entry is both searchable and bindable, and that the bind only succeeds over an encrypted connection. By the end of this chapter, the same `posixAccount`/`posixGroup` attributes you write here — `uidNumber`, `gidNumber`, `homeDirectory`, `loginShell` — are exactly what Module 3's `sssd` client reads back out on the other side.

---

## Part I: LDIF, the Language of Directory Content

Every change you make to directory data — as opposed to `cn=config` itself — is expressed in **LDIF** (LDAP Data Interchange Format). It is a plain-text format, but its rules are strict enough to be worth stating explicitly, because violating them silently produces confusing errors.

A minimal LDIF entry needs exactly one `dn:` line naming its unique position in the tree, followed by one or more `objectClass:` lines declaring which schema classes govern the entry, plus whatever attributes those classes require or allow. When a file contains multiple entries, a **blank line** is the entry separator:

```ldif
dn: ou=people,dc=example,dc=com
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=example,dc=com
objectClass: organizationalUnit
ou: groups
```

Miss that blank line and `ldapadd` will not politely skip ahead to a second entry — it will attempt to parse both stanzas as one malformed entry and reject the whole file. This is one of the most common, and most confusing-to-diagnose, LDIF mistakes: it looks like a content problem when it is actually a formatting one.

`organizationalUnit` is the standard structural class for a directory "folder." Notice that `ou: people` appears both in the `dn:` (as the RDN — the relative distinguished name, the leftmost component that makes this entry's position unique) and again as its own attribute line. That repetition is required, not redundant — the RDN and the attribute are related but are not the same syntactic thing to the LDAP parser.

Apply this structure as the directory admin identity Module 1 configured:

```bash
ldapadd -x -W -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f /tmp/ou-structure.ldif
```

`-x` selects simple authentication (a bind DN plus a password) rather than SASL. `-W` prompts interactively for that password instead of accepting it as a command-line argument, which would otherwise sit in shell history and be visible to anyone running `ps` on the box at the wrong moment. `-D` names the identity performing the add. Under the hood, `ldapadd` is nothing more than `ldapmodify` run with an implicit "add" operation — the same tool, a different verb.

---

## Part II: A Group and a User, Together

LDAP has an important structural rule: **parent entries must exist before child entries can be created beneath them.** Unlike a filesystem's `mkdir -p`, there is no implicit "create the intermediate directories for me" behavior. `ou=people` and `ou=groups` from Part I exist specifically so the entries below can be added into them at all.

Write a POSIX group and a POSIX user in one file:

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

A few details here are worth slowing down for. `objectClass` appears three times on the user entry — once per class it belongs to. That is normal, expected, and required; it is not three attempts at the same thing.

`posixGroup` requires `cn` and `gidNumber` — that is genuinely everything it needs. `posixAccount`, on the other hand, is an **auxiliary** object class: it adds POSIX-specific attributes (`uidNumber`, `gidNumber`, `homeDirectory`, `loginShell`) but does not, by itself, provide the structural backbone every LDAP entry needs. That is why the user entry also carries `inetOrgPerson` (which supplies `cn`/`sn` and satisfies the requirement that every entry have exactly one structural object class) alongside `posixAccount`. An entry with `posixAccount` alone, and nothing structural beside it, is invalid in most schemas — this is one of the most common mistakes when hand-writing a first POSIX user LDIF.

Every one of these fields — `uidNumber`, `gidNumber`, `homeDirectory`, `loginShell` — is not decoration. It is precisely what a client's NSS layer will read back out in Module 3 to build a working `passwd`-style entry for this user.

Apply it the same way as Part I:

```bash
ldapadd -x -W -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f /tmp/lfcsuser.ldif
```

`ldapadd` does not care whether the entries in a file are organizational units, groups, or user accounts — it is all just LDIF against the same tree.

---

## Part III: Setting a Password Two Different Ways

Notice that Part II's LDIF has no `userPassword` line. There are two legitimate ways to give this entry a password, and it is worth understanding both, because you will see each used depending on context.

**Live, connected, and interactive** — using `ldappasswd` against the already-created entry:

```bash
ldappasswd -x -W -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -S "uid=lfcsuser,ou=people,dc=example,dc=com"
```

`-S` prompts for the *new* password belonging to the target DN — a separate prompt from `-W`'s admin bind password. This runs the LDAP Password Modify extended operation live against the running server: the admin bind performs the change on the user's behalf, and the plaintext password is only ever typed at this one interactive prompt — never placed in a command-line argument or saved into a file.

**Offline and pre-computed** — using `slappasswd` to produce a hash first, exactly as Module 1 did for the admin password, then embedding that hash directly as a `userPassword:` attribute line inside the entry's LDIF at creation time. This second approach is what you will see in scripted, non-interactive setups (including this course's own lab bootstrap automation) — there is no live directory connection required at the moment the hash is generated, which makes it the natural choice whenever a password needs to be set as part of an unattended provisioning step rather than a human typing at a prompt.

Both approaches produce a working, hashed password in the directory. Neither should ever leave a plaintext password sitting in a saved file.

---

## Part IV: Two Different Claims, Two Different Proofs

Here is the idea this entire module is really building toward: **an entry existing and a bind succeeding are two different claims, and only one command actually proves each.**

A plain anonymous search confirms the entry is there and readable, but proves nothing about encryption:

```bash
ldapsearch -x -H ldap://127.0.0.1 -b "dc=example,dc=com" "(uid=lfcsuser)"
```

Requiring StartTLS changes that:

```bash
ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "dc=example,dc=com" "(uid=lfcsuser)"
```

The distinction between `-Z` and `-ZZ` matters more than it looks. A single `-Z` *attempts* StartTLS but silently falls back to the original plaintext connection if negotiation fails — success tells you nothing conclusive, because you cannot tell from the result whether TLS was actually used or quietly skipped. `-ZZ` *requires* the StartTLS upgrade to succeed and aborts the whole operation with an explicit error if it does not. When the goal is to *prove* encryption happened, `-ZZ` is the only one of the two that actually does that.

Even a successful `-ZZ` search, though, only proves the entry is readable over an encrypted connection — it says nothing about whether `lfcsuser`'s own password is correct, because that search almost certainly ran as the admin identity or anonymously. Proving the *credential* itself requires an actual bind attempt as that user:

```bash
ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -W -ZZ -H ldap://127.0.0.1
```

`ldapwhoami` performs the "Who am I?" extended operation. There is no result set to parse, no filter to get subtly wrong — it returns exactly one thing: the identity the server associates with the bind that was just attempted, or an explicit failure. Combined with `-ZZ`, a correct response (typically echoing back the bind DN) is the cleanest possible single-command proof of three things at once: the entry exists, the password is correct, and the whole exchange happened over TLS.

It is worth deliberately trying the same bind *without* `-ZZ` first:

```bash
ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -W -H ldap://127.0.0.1
```

Depending on whether the server enforces TLS for simple binds, this either fails outright with a confidentiality-required error, or "succeeds" while having sent the password unencrypted. Either outcome is instructive: it makes concrete, rather than theoretical, why the `-ZZ` version above is the one that actually matters for a directory that claims to take security seriously.

---

## Self-Check and Verification

Test your understanding before moving on to client integration:
1.  **LDIF Structure**: What are the two required components of every LDIF entry, and what does a blank line mean between two entries in the same file?
2.  **Object Classes**: Why does a `posixAccount` entry almost always need `inetOrgPerson` (or another structural class) alongside it, instead of `posixAccount` by itself? *(Answer: `posixAccount` is an auxiliary class supplying only POSIX attributes; it doesn't provide the structural backbone every entry requires, so it's paired with a structural class like `inetOrgPerson`.)*
3.  **Proving TLS**: Why does `-ZZ` prove something that `-Z` cannot? *(Answer: `-Z` silently falls back to plaintext on failure, so success is ambiguous; `-ZZ` aborts on failure, so success is unambiguous proof the encrypted upgrade actually happened.)*
4.  **Search vs. Bind**: If `ldapsearch` finds `lfcsuser`'s entry, have you proven the password is correct? *(Answer: No — a search proves the entry exists and is readable under whatever identity performed the search; only a successful bind as that specific user, e.g. via `ldapwhoami`, proves the credential itself is valid.)*
