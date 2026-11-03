# LDIF And The First Drawers

Astronaut, every card that goes into the fleet registry is written on the same paper form: LDIF. This part shows you the rules of that form, and how to add the first two drawers, `ou=people` and `ou=groups`.

## LDIF, the language of directory content

Every change to directory data is written in **LDIF** (LDAP Data Interchange Format). It is plain text, but it has strict rules, and breaking them gives confusing errors.

### The two drawers as LDIF

<!-- astrona:playground:renew -->

Save this file with two entries as `/tmp/ou-structure.ldif`:

```ldif
dn: ou=people,dc=example,dc=com
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=example,dc=com
objectClass: organizationalUnit
ou: groups
```

`organizationalUnit` is the standard class for a drawer, a "folder" in the registry. Each entry has one `dn:` line naming its position, one or more `objectClass:` lines naming the schema classes that govern it, and the attributes those classes require.

### The rules behind the form

Three rules are worth knowing before you write your own:

- **A blank line separates entries.** Without it, the parser reads two stanzas as one broken entry.
- **The RDN repeats as an attribute.** `ou: people` appears in the `dn:` (as the **RDN**, the relative distinguished name, the leftmost part) and again as its own attribute line. That repetition is required, not wasted: the parser treats the RDN and the attribute as different things.
- **Every entry needs its required attributes.** The object classes decide which ones.

## Adding entries with `ldapadd`

`ldapadd` is `ldapmodify` with an automatic "add". You run it as the administrator: `-x` selects a simple bind (bind DN plus password), `-D` names who binds, and `-W` asks for the password at a prompt so it stays out of shell history and the `ps` output.

### Add the two containers

Apply the file you saved, and enter `LdapRoot!2024` at the prompt:

```sh
ldapadd -x -W -D "cn=admin,dc=example,dc=com" -H ldap://127.0.0.1 -f /tmp/ou-structure.ldif
```

Expect something like:

```text
Enter LDAP Password:
adding new entry "ou=people,dc=example,dc=com"
adding new entry "ou=groups,dc=example,dc=com"
```

Two `adding new entry` lines: the blank line in the file told `ldapadd` that these were two separate entries. Remove that blank line, and it tries to read both stanzas as one entry and rejects the whole file.

## Common pitfalls

> [!WARNING]
> - **A missing blank line between LDIF entries.** `ldapadd` reads them as one malformed entry and rejects the file. It looks like a content error, but it is a formatting error.
> - **Dropping the `ou:` attribute line.** The RDN in the `dn:` does not replace it; the entry is rejected.
> - **A password on the command line with `-w` on a real host.** It shows up in `ps` and shell history. Use `-W` to be asked.
