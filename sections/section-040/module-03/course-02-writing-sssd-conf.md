# Writing sssd.conf

Astronaut, the records officer needs written orders: which registry to ask, how to seal the channel, and which badge to trust. This part shows you how to write `/etc/sssd/sssd.conf`, what each line does, and the permission check `sssd` runs on its own orders.

## The domain section

`sssd`'s behaviour lives in `/etc/sssd/sssd.conf`: one `[sssd]` section, plus one `[domain/NAME]` section for each identity source.

### Write the file and check its syntax

First, create the directory with the right mode:

<!-- astrona:playground:renew -->

```sh
sudo install -d -m 711 /etc/sssd
```

Save this as `/etc/sssd/sssd.conf`:

```ini
[sssd]
config_file_version = 2
services = nss, pam
domains = example.com

[domain/example.com]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://127.0.0.1
ldap_search_base = dc=example,dc=com
ldap_id_use_start_tls = true
ldap_tls_cacert = /etc/ldap/certs/ldap-server.crt
cache_credentials = True
```

Apply it, by giving the file the owner and mode `sssd` demands:

```sh
sudo chmod 600 /etc/sssd/sssd.conf
sudo chown root:root /etc/sssd/sssd.conf
```

Then check the result:

```sh
sudo sssctl config-check
```

Expect something like:

```text
Issues identified by validators: 0
Messages generated during config merge: 0
Used configuration snippet files: 0
```

`sssctl config-check` reads the file and its permissions and reports zero issues. A misspelled option or a domain header that does not match would show up here as a validator issue.

### The lines that trip up a first attempt

Here is what the important lines do:

- `services = nss, pam` switches on the two front ends. Without `nss`, `getent` and `id` never work, however right the domain section is. Without `pam`, logins never go through `sssd`. They are independent switches, and you need both.
- `domains = example.com` names the active domain. The `[domain/example.com]` header must match it **exactly**, or the section is quietly ignored.
- `id_provider` answers "where does user and group data come from?"; `auth_provider` answers "where is a password checked?". Here both point at LDAP. A real setup might use LDAP for identity and Kerberos for passwords; the format splits them on purpose.
- `ldap_id_use_start_tls = true` seals the connection the same way `ldapsearch -ZZ` does, because the server requires TLS. `ldap_tls_cacert` points at a local copy of the server's certificate, so `sssd` trusts the self-signed badge instead of rejecting the handshake. For quick troubleshooting only, `ldap_tls_reqcert` can be relaxed, but trusting the specific certificate is the correct fix, not switching checks off.
- `cache_credentials = True` is the payoff: a user who logged in before can still log in from the cache during a short outage.

## The permission check SSSD performs on itself

`sssd.conf` holds connection details that should not be readable by everyone. `sssd` does not just hope you remember: it checks when it starts and refuses to run with a loose file. Mode `600`, owner `root:root`, is the required state.

### Loosen the file and watch sssd refuse

Make the file readable by everyone, try a restart, read the log, and put the mode back:

```sh
sudo chmod 644 /etc/sssd/sssd.conf
sudo systemctl restart sssd; echo "restart exit: $?"
sudo journalctl -u sssd -n 5 --no-pager | grep -i perm
sudo chmod 600 /etc/sssd/sssd.conf
```

Expect something like:

```text
restart exit: 1
... File ownership and permissions check failed. Expected root:root and 0600.
```

With mode `644`, the restart fails with a clear ownership and permissions message, nothing to do with `ldap_uri` or the domain section. This failure surprises people because it looks unrelated to the content of the file. Setting `600` again clears it.

## Common pitfalls

> [!WARNING]
> - **A `[domain/example.com]` header that does not match `domains = example.com`.** The section is quietly ignored, with no error.
> - **`sssd.conf` at `644` or readable by its group.** `sssd` refuses to start with a permissions error that looks unrelated to the file's content. Use `chmod 600` and `chown root:root`.
> - **A self-signed certificate rejected.** Set `ldap_tls_cacert` to a local copy of the server's certificate. Do not switch off certificate checks as the "fix".
> - **Leaving out `nss` or `pam` in `services`.** Lookups or logins never reach `sssd`.
