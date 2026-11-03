# Naming The Directory And Its Administrator

Astronaut, an empty registry still needs a name on its top shelf and one official who may write in it. This part shows you how to give `slapd` its base DN and an administrator, with the password stored only as a hash.

## Where the name and the administrator live

The base DN the server answers for, and the identity allowed to write under it, live on the `olcDatabase={1}mdb,cn=config` entry. Three attributes do the job:

- `olcSuffix`: the base DN, the registry's top shelf.
- `olcRootDN`: the administrator's bind DN.
- `olcRootPW`: the administrator's password, as a hash.

`olcRootDN` and `olcRootPW` define an identity with full access to this one database, separate from any normal entry. It is the identity you use later to add users.

### Find the database entry on your machine

The number in `{1}` can differ between installs. This search shows which entry it is on your system:

<!-- astrona:playground:renew -->

```sh
sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcMdbConfig)" dn
```

Look for the `dn:` line; on the playground it is `olcDatabase={1}mdb,cn=config`.

## A hash, never a plaintext password

Never write a plaintext password into an LDIF file. LDIF files get pasted into tickets and committed to repositories by accident. A plaintext `olcRootPW` in one is a permanent leak; a hash is not.

### Make the hash with `slappasswd`

`slappasswd` (short for *slap password*) makes a salted `{SSHA}` hash that `slapd` can store. Run it with the administrator password:

```sh
slappasswd -s 'LdapRoot!2024'
```

It prints one line that starts with `{SSHA}`. Copy that whole line; it replaces `<ADMIN_HASH>` in the file below. `-s '<password>'` takes the password as an argument, which suits a scripted flow. Run `slappasswd` with no `-s` to be asked for it instead, so it stays out of your shell history.

## Writing the change

A modify LDIF has a fixed shape: a `dn:` line naming the target entry, `changetype: modify`, then one or more `replace:` blocks, separated by a line with only `-` on it.

### Name the directory, then read the setting back

Save this as `/tmp/set-suffix.ldif`, with your hash in place of `<ADMIN_HASH>`:

```ldif
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
-
replace: olcRootDN
olcRootDN: cn=admin,dc=example,dc=com
-
replace: olcRootPW
olcRootPW: <ADMIN_HASH>
```

Apply it:

```sh
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set-suffix.ldif
```

Then check the result:

```sh
sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config -LLL "(olcSuffix=*)" olcSuffix olcRootDN
```

Expect something like:

```text
modifying entry "olcDatabase={1}mdb,cn=config"
dn: olcDatabase={1}mdb,cn=config
olcSuffix: dc=example,dc=com
olcRootDN: cn=admin,dc=example,dc=com
```

The `modifying entry` line comes from `ldapmodify` and means the change was applied with no restart. The read-back shows that `slapd` now answers for `dc=example,dc=com`, with `cn=admin,dc=example,dc=com` as its administrator. `olcRootPW` is not shown here; it is stored as a hash.

## Common pitfalls

> [!WARNING]
> - **A plaintext `olcRootPW`.** Always run `slappasswd` first. The hash goes in the LDIF; the plaintext never touches disk.
> - **A missing `-` line between `replace:` blocks.** `ldapmodify` then reads the blocks as one change and rejects the file.
> - **The wrong database number.** If your install uses another `{N}mdb`, the `dn:` line must match it. Check with the `olcMdbConfig` search.
