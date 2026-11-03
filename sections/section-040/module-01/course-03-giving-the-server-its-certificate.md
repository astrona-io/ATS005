# Giving The Server Its Certificate

Astronaut, a registry that will seal its signals needs an ID badge (a TLS certificate) and a secret key it can actually reach. This part shows you who runs `slapd`, why that account must be able to read the key, and how to tell `cn=config` where the certificate lives.

## A key the server can actually read

`slapd` does **not** run as `root`. It runs as an unprivileged service account: `openldap` on Debian and Ubuntu, often `ldap` on Red Hat style systems. That account must be able to *read* the private key, or TLS setup fails when `slapd` starts.

### Who runs slapd, and can it read the key

Check the account, the file permissions, and a real read as `openldap`:

<!-- astrona:playground:renew -->

```sh
ps -o user= -C slapd
ls -l /etc/ldap/certs/
sudo -u openldap cat /etc/ldap/certs/ldap-server.key >/dev/null && echo "openldap CAN read the key"
```

Expect something like:

```text
openldap
-rw-r--r-- 1 openldap openldap 1391 Aug 30 12:00 ldap-server.crt
-rw-r----- 1 openldap openldap 1704 Aug 30 12:00 ldap-server.key
openldap CAN read the key
```

`slapd` runs as `openldap`. The key is owned by `openldap`, readable by its group, and not readable by everyone else. The read test as that user succeeds. If that last line failed, TLS would break at the next restart, and this would be the cause, not the certificate.

### The two opposite mistakes

A key that everyone can read is a security mistake. A key only `root` can read while `slapd` runs as `openldap` is the equally common opposite mistake. It causes a startup failure that looks like a bad certificate rather than a permission problem.

The playground's key is already `openldap:openldap`, mode `640`. On another machine, this is the pattern:

```sh
sudo chown openldap:openldap /etc/ldap/certs/ldap-server.key /etc/ldap/certs/ldap-server.crt
sudo chmod 640 /etc/ldap/certs/ldap-server.key
sudo chmod 644 /etc/ldap/certs/ldap-server.crt
```

## Wiring the certificate into `cn=config`

TLS belongs to the whole server, not to one database, so this change targets `cn=config` itself. It sets three attributes:

- `olcTLSCertificateFile`: the certificate (the registry's ID badge).
- `olcTLSCertificateKeyFile`: the private key.
- `olcTLSCACertificateFile`: the certificate authority to trust. For a self-signed certificate, it points back at the certificate itself, because the certificate is its own trust anchor.

### Apply the TLS attributes and confirm they stuck

Save this as `/tmp/set-tls.ldif`:

```ldif
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/certs/ldap-server.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/certs/ldap-server.key
-
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ldap/certs/ldap-server.crt
```

Apply it, and restart `slapd`:

```sh
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set-tls.ldif
sudo systemctl restart slapd
```

Then check the result:

```sh
sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config -LLL "(cn=config)" olcTLSCertificateFile olcTLSCertificateKeyFile
```

Expect something like:

```text
modifying entry "cn=config"
dn: cn=config
olcTLSCertificateFile: /etc/ldap/certs/ldap-server.crt
olcTLSCertificateKeyFile: /etc/ldap/certs/ldap-server.key
```

`slapd` came back up after the restart. If it had not, `journalctl -u slapd -n 30` would show a certificate, key or permission reason. The attributes read back with the paths you set: the server now has a TLS identity.

Unlike most `cn=config` changes, this one needs a restart, because `slapd` builds its TLS listener when it starts. Restarting `slapd` on a one-machine playground is safe. On a production directory with live clients, treat it as a short outage and schedule it.

## Common pitfalls

> [!WARNING]
> - **A key only `root` can read while `slapd` runs as `openldap`.** TLS fails at startup, and the error points you at the certificate instead. Check `ps -o user= -C slapd` and the key's owner and mode.
> - **Forgetting the restart after the TLS change.** The listener is built at startup, so the attributes alone change nothing yet.
> - **Pointing `olcTLSCACertificateFile` somewhere else for a self-signed certificate.** A self-signed certificate is its own authority; point it at the certificate itself.
