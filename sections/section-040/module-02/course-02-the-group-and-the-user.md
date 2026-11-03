# The Group And The User

Astronaut, a registry card for a crew member needs the right kind of card, not just the right fields. This part shows you why a POSIX user needs two kinds of object class, watches the server reject a card that has only one, and then adds the `developers` group and the user `lfcsuser`.

## Parents first, and two kinds of object class

LDAP has a rule with no filesystem match: **a parent entry must exist before any child can be created under it.** There is no `mkdir -p`. That is why `ou=people` and `ou=groups` come first: the group and the user can only be placed inside existing drawers.

### Watch a card with no backbone get rejected

Object classes come in two kinds, and a card needs the right mix. Try to add a user card that has only `posixAccount`.

Save this as `/tmp/broken.ldif`:

<!-- astrona:playground:renew -->

```ldif
dn: uid=broken,ou=people,dc=example,dc=com
objectClass: posixAccount
uid: broken
cn: broken
uidNumber: 12345
gidNumber: 5000
homeDirectory: /home/broken
```

Apply it:

```sh
ldapadd -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f /tmp/broken.ldif
```

Expect something like:

```text
adding new entry "uid=broken,ou=people,dc=example,dc=com"
ldap_add: Object class violation (65)
        additional info: no structural object class provided
```

`posixAccount` alone is not enough, and the server refuses the entry. (`-w '<password>'` passes the password on the command line. That is fine on a throwaway playground, but `-W`, which asks for it, is the habit for a real machine.)

### Structural and auxiliary classes

Here is the rule behind that error:

- A **structural** class (such as `organizationalUnit`, or `inetOrgPerson` for a person) gives an entry its backbone. Every entry must have exactly one.
- An **auxiliary** class adds attributes but no backbone. `posixAccount` is auxiliary: it supplies `uidNumber`, `gidNumber`, `homeDirectory` and `loginShell`, but it cannot stand alone.

An entry with `posixAccount` and nothing structural is invalid. It is one of the most common mistakes with a first POSIX user.

## Adding the real group and user

The real user card fixes the error by carrying `inetOrgPerson` (structural; it supplies `cn` and `sn`) and `shadowAccount` (auxiliary; it adds shadow-style password aging attributes) beside `posixAccount`. A `posixGroup` needs only `cn` and `gidNumber`; it is complete on its own.

### Add the group and the user, then read them back

Save this as `/tmp/lfcsuser.ldif`:

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

Apply it:

```sh
ldapadd -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f /tmp/lfcsuser.ldif
```

Then check the result:

```sh
ldapsearch -x -H ldap://127.0.0.1 -b "dc=example,dc=com" -LLL "(uid=lfcsuser)" uidNumber gidNumber homeDirectory loginShell
```

Expect something like:

```text
adding new entry "cn=developers,ou=groups,dc=example,dc=com"
adding new entry "uid=lfcsuser,ou=people,dc=example,dc=com"
dn: uid=lfcsuser,ou=people,dc=example,dc=com
uidNumber: 10001
gidNumber: 5000
homeDirectory: /home/lfcsuser
loginShell: /bin/bash
```

Both entries are added, with three `objectClass` lines on the user. The search shows the POSIX attributes stored and readable. They are the raw material a Linux client turns into a `passwd` line: badge number, team number, quarters and console.

## Common pitfalls

> [!WARNING]
> - **`posixAccount` with no structural class.** `Object class violation (65)`, "no structural object class provided". Add `inetOrgPerson`.
> - **Adding a child before its parent `ou=` exists.** It fails; LDAP never creates a parent for you.
> - **A user `gidNumber` with no matching group.** The card is accepted, but clients cannot name the user's primary group. Add the `posixGroup` with that `gidNumber`.
