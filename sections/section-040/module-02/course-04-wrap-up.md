# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module filled an empty fleet registry with drawers, a group card and a user card, and proved that the user can bind over a sealed channel.

**From [LDIF And The First Drawers](./course-01-ldif-and-the-first-drawers.md):**

- An LDIF entry has a `dn:` line, `objectClass:` lines and the required attributes; a blank line separates entries.
- The RDN (for example `ou: people`) appears in the `dn:` and again as its own attribute.
- `ldapadd -x -W -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f <file>` adds entries as the administrator.

**From [The Group And The User](./course-02-the-group-and-the-user.md):**

- A parent entry must exist before a child; add `ou=people` and `ou=groups` first.
- Every entry needs exactly one structural class. `posixAccount` is auxiliary, so a POSIX user also needs `inetOrgPerson`.
- A `posixGroup` needs only `cn` and `gidNumber`.

**From [Setting The Password And Proving The Bind](./course-03-setting-the-password-and-proving-the-bind.md):**

- `ldappasswd` sets a password live; a `slappasswd` hash in `userPassword` works offline. No plaintext goes into a file.
- `-ZZ` requires StartTLS; `-Z` may quietly fall back to plain text.
- `ldapwhoami -ZZ` as the user proves the entry, the password and the encryption in one command.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [LDAP Directory Population & Verified TLS Bind Lab](../../../labs/lab-042/docs/question.md) | Setting The Password And Proving The Bind | added `ou=people`, `ou=groups`, the `developers` group and `lfcsuser`, set the password and proved a bind over required StartTLS |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. What separates two entries in one LDIF file?</summary>

A blank line. Without it, `ldapadd` reads both stanzas as one malformed entry.
</details>

<details>
<summary>2. Why must <code>ou=people</code> exist before you add <code>uid=lfcsuser,ou=people,dc=example,dc=com</code>?</summary>

LDAP never creates a parent entry for you. A child can only be added under a parent that already exists.
</details>

<details>
<summary>3. <code>ldapadd</code> fails with "no structural object class provided". What is missing?</summary>

A structural class. `posixAccount` is auxiliary; add `inetOrgPerson` to the entry.
</details>

<details>
<summary>4. What is the difference between <code>-Z</code> and <code>-ZZ</code>?</summary>

`-Z` tries StartTLS but continues in plain text if it fails. `-ZZ` requires StartTLS and stops with an error if it fails.
</details>

<details>
<summary>5. A <code>-ZZ</code> search finds <code>lfcsuser</code>. Does that prove the user's password is right?</summary>

No. It proves the entry is readable over TLS by whoever searched. A bind as the user, for example `ldapwhoami -ZZ`, proves the password.
</details>

<details>
<summary>6. Name two ways to give a directory user a password without a plaintext password in a file.</summary>

`ldappasswd` (live, with `-S` to be asked), or a `slappasswd` hash in the entry's `userPassword` attribute.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy ldap-populate-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-042
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-040/module-02/playground`. It always starts clean, so nothing you broke carries over.

> *An entry that exists and an entry you can bind as over TLS are two claims: prove both.*
