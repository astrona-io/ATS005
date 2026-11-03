# The Configuration Is A Tree

Astronaut, most services keep their settings in one file you edit and restart. The fleet registry does not. This part shows you where `slapd` keeps its configuration, the tool family you use to read and change it, and how to look at it on your playground.

## The directory that is not a file

If you have set up other Linux services, your first instinct with `slapd` (short for *standalone LDAP daemon*) is to find one configuration file, edit it, and restart. That fails here. Modern OpenLDAP keeps its running configuration as a live tree of entries rooted at `cn=config`, often called **OLC** (on-line configuration).

### Look at the server and its configuration tree

Check that `slapd` runs, see which ports it listens on, and list the entries of the configuration tree:

<!-- astrona:playground:renew -->

```sh
systemctl is-active slapd
sudo ss -tlnp | grep -E ':389|:636'
sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config -LLL dn
```

Expect something like:

```text
active
LISTEN 0  1024  *:389  *:*  users:(("slapd",pid=800,fd=8))
dn: cn=config
dn: cn=schema,cn=config
dn: cn={0}core,cn=schema,cn=config
dn: olcDatabase={-1}frontend,cn=config
dn: olcDatabase={0}config,cn=config
dn: olcDatabase={1}mdb,cn=config
```

Port `389` is listening, `636` is not yet. The `ldapsearch` output is the *configuration itself*, returned as directory entries. `olcDatabase={1}mdb,cn=config` is the entry that backs your real data. `-LLL` only trims comments and version lines from the output.

`ss` (short for *socket statistics*) lists network sockets. `ss -tlnp` reads as **t**CP sockets, **l**istening only, **n**umeric ports, with the owning **p**rocess. It is the quickest way to see which ports `slapd` has open.

### What the tree model gives you

Every setting is an LDAP entry with attributes inside that tree: the base DN served, the administrator, the TLS paths. Think of it as the registry office's own rule book, kept as registry cards too. That has three benefits:

- Most changes take effect without a restart, because `slapd` reads its own tree.
- The configuration is protected by the same access controls as directory data.
- You inspect it with the same tools you use for ordinary directory data.

## The `ldap*` tool family

The tools are a family, each named `ldap` plus the operation it performs, and all taking the same connection options. Learn the options once and every command reads the same way.

### The tools and their shared options

The tools:

- `ldapsearch` reads entries.
- `ldapmodify` changes entries.
- `ldapadd` creates entries.
- `ldappasswd` sets a password.
- `ldapwhoami` reports who a bind authenticated as.

The shared options:

| Option | Meaning |
| --- | --- |
| `-H` | The host address (URI), for example `ldap://127.0.0.1` or `ldapi:///` |
| `-x` | Simple bind: a bind DN and a password |
| `-D` | The bind DN: who you show at the registry window |
| `-W` | Ask for the bind password at a prompt |
| `-Y` | The SASL mechanism, for example `EXTERNAL` |
| `-Z` / `-ZZ` | Try StartTLS / require StartTLS |

### Changing the configuration: LDIF over `ldapi:///`

Because the configuration is a tree, every configuration change is itself an LDAP operation. You write a small **LDIF** (LDAP Data Interchange Format) file, the paper form that describes what should change. You apply it with `ldapmodify` against `cn=config`.

You authenticate over a local-only channel: the `ldapi:///` UNIX socket with SASL's `EXTERNAL` mechanism. `-Y EXTERNAL -H ldapi:///` tells the client "use my operating system identity (`root`, through the socket), not a bind DN and password". `slapd` treats a local `root` process that reaches it this way as the administrator of `cn=config`.

## Common pitfalls

> [!WARNING]
> - **Looking for `/etc/ldap/slapd.conf`.** There is no such file on a modern install. Change `cn=config` with `ldapmodify -Y EXTERNAL -H ldapi:///`.
> - **Forgetting `sudo` on `ldapi:///` commands.** SASL EXTERNAL uses your operating system identity. As a normal user, you are not the administrator of `cn=config`.
> - **Mixing up `{1}mdb` and `cn=config`.** The database entry holds the data settings; `cn=config` itself holds server-wide settings such as TLS.
