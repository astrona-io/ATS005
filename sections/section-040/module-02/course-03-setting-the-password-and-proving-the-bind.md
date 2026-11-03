# Setting The Password And Proving The Bind

Astronaut, a registry card with no door code cannot be used to come aboard. This part shows you two ways to give `lfcsuser` a password, and then two separate proofs: that the card is searchable over a sealed channel, and that a bind as `lfcsuser` really works.

## Setting a password, two ways

The user LDIF has no `userPassword` attribute. There are two proper ways to add one, and neither leaves a plaintext password in a file.

### Live and interactive: `ldappasswd`

`ldappasswd` sets the password on an existing entry:

<!-- astrona:playground:renew -->

```sh
ldappasswd -x -W -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -S "uid=lfcsuser,ou=people,dc=example,dc=com"
```

`-S` asks for the *new* password for the target DN, at a separate prompt from `-W`'s administrator password. It runs the LDAP Password Modify extended operation live; the plaintext is typed only at that prompt.

### Offline and computed in advance: `slappasswd`

`slappasswd` makes a hash, and that hash goes straight into the entry's LDIF as a `userPassword:` line when the entry is created. Scripted provisioning works this way, with no live connection needed when the hash is made. Either way, a hashed password ends up in the directory and no plaintext is left in a file.

### Set the password and confirm it took

Set the password with `-s`, which supplies the new password on the command line for the playground, then read the attribute as the administrator:

```sh
ldappasswd -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -s 'LfcsLdap!2024' "uid=lfcsuser,ou=people,dc=example,dc=com"
ldapsearch -x -w 'LdapRoot!2024' -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -b "uid=lfcsuser,ou=people,dc=example,dc=com" -LLL userPassword
```

Expect something like:

```text
dn: uid=lfcsuser,ou=people,dc=example,dc=com
userPassword:: e1NTSEF9...redacted...
```

The `userPassword` attribute now exists, stored as a `{SSHA}` hash. The `::` and the base64 text are just how `ldapsearch` prints a value that is not plain text. On a real host, use `-S` to be asked instead of `-s`.

## Two claims, two proofs

An entry *existing* and a bind *succeeding* are different claims, and different commands prove each one.

### Searchable, and over a sealed channel

A plain search with no bind only shows that the entry is there and readable. It says nothing about encryption:

```sh
ldapsearch -x -H ldap://127.0.0.1 -b "dc=example,dc=com" "(uid=lfcsuser)"
```

Adding `-ZZ` requires the StartTLS upgrade to succeed first. The difference between `-Z` and `-ZZ` matters. A single `-Z` *tries* StartTLS but quietly falls back to plain text if it fails, so success proves nothing. `-ZZ` *requires* it and stops with an error otherwise. To *prove* encryption, only `-ZZ` will do.

### The credential itself: `ldapwhoami`

Even a successful `-ZZ` search only proves the entry is readable over TLS. It does not prove that `lfcsuser`'s own password is right, because that search ran without a bind or as the administrator. Proving the credential needs a bind *as that user*.

`ldapwhoami` runs the "Who am I?" extended operation. There is no result list to misread: it returns exactly the identity the server tied to the bind, or a clear failure.

```sh
ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -W -ZZ -H ldap://127.0.0.1
```

### Search proof, then bind proof

Run the sealed search, a bind with the right password, and a bind with a wrong one:

```sh
ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "dc=example,dc=com" -LLL "(uid=lfcsuser)" dn
ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -w 'LfcsLdap!2024' -ZZ -H ldap://127.0.0.1
ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -w 'wrong-password' -ZZ -H ldap://127.0.0.1
```

Expect something like:

```text
dn: uid=lfcsuser,ou=people,dc=example,dc=com
dn:uid=lfcsuser,ou=people,dc=example,dc=com
ldap_bind: Invalid credentials (49)
```

The `-ZZ` search finds the entry over a channel that had to be encrypted. The first `ldapwhoami` binds *as* `lfcsuser` over TLS, and the server repeats the DN back. That one command proves the entry exists, the password is right, and the channel is encrypted. The wrong-password attempt fails with `Invalid credentials (49)`, which is what a real bind check looks like when it should fail.

> [!TIP]
> When you must prove that a user can log in to a directory, reach for `ldapwhoami -ZZ` as that user. A search only proves who ran the search could read the entry.

## Common pitfalls

> [!WARNING]
> - **Trusting a `-Z` result.** It may have fallen back to plain text. Use `-ZZ` when the point is to prove TLS.
> - **Concluding that a search proves the password.** It proves the entry is readable by whoever searched. Only `ldapwhoami` (or a real bind) as that user proves the credential.
> - **A password on the command line on a real host.** `-w` and `-s` show up in `ps` and shell history. Use `-W` and `-S` to be asked.

## Your mission: LDAP Directory Population & Verified TLS Bind Lab

You can now write LDIF entries in the right order, build a valid POSIX user and group, set a password and prove a bind over required TLS. Now prove it in a graded mission: a fresh, empty, TLS-secured registry that you fill with the drawers, the `developers` group and the user `lfcsuser`.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ldap-populate-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-042
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-042
```

Read the task in [`question.md`](../../../labs/lab-042/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-042
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-042
astrona start ldap-populate-playground
```
