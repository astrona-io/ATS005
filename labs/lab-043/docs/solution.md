# Solution Walkthrough

Follow these steps on the terminal to wire this host up as an LDAP client via `sssd`.

---

## Step 1: Write the sssd.conf domain section

```bash
sudo vi /etc/sssd/sssd.conf
```

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

`ldap_uri` and `ldap_search_base` point at the loopback server this same host is already running. `ldap_id_use_start_tls = true` matches the server's TLS enforcement from Module 1; `ldap_tls_cacert` points at the server's own certificate so `sssd` trusts it (it is self-signed, so the certificate is its own trust anchor).

---

## Step 2: Set the correct ownership and permissions

```bash
sudo chown root:root /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf
```

`sssd` checks this itself at startup and refuses to run against a looser configuration.

---

## Step 3: Add sss to nsswitch.conf

```bash
sudo vi /etc/nsswitch.conf
```

Change:

```
passwd: files
group:  files
```

to:

```
passwd: files sss
group:  files sss
```

---

## Step 4: Enable and start sssd

```bash
sudo systemctl enable --now sssd
sudo systemctl status sssd
sudo journalctl -u sssd -n 50 --no-pager
```

Confirm the service actually started cleanly — if Step 2's permissions were wrong, this is where it surfaces.

---

## Step 5: Verify NSS resolution first

```bash
getent passwd lfcsuser
getent group developers
id lfcsuser
```

Expect a full `passwd`-style line for `lfcsuser` (UID `10001`, home `/home/lfcsuser`, shell `/bin/bash`), a `developers` group entry with GID `5000`, and `id lfcsuser` showing both correctly with no errors.

---

## Step 6: Confirm local accounts are unaffected

```bash
getent passwd root
id root
```

Expect completely normal, unchanged output — `root` resolves via `files`, independent of `sssd`'s state.

Once all of the above pass, run the local validation suite to pass the lab!
