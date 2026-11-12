# Opening Port 636 And Proving TLS

Astronaut, a registry can seal its channel in two ways, and you should offer both. This part shows you the difference between StartTLS and LDAPS, how to open the LDAPS listener, and how to prove at two separate layers that encryption really works.

## StartTLS on 389, or native LDAPS on 636

OpenLDAP offers encryption in two ways. The difference matters when you troubleshoot later, because a client may use either one.

### The two ways to seal the channel

Here is how they differ:

- **Native LDAPS**, on port 636, wraps the whole connection in TLS from the first byte, like HTTPS. The channel is sealed from the first moment, before any LDAP is spoken.
- **StartTLS**, on the standard port 389, starts as a plain connection and seals it partway through the conversation, through an LDAP extended operation. Most modern tools (`ldapsearch -Z` or `-ZZ`, `sssd`) use this by default.

A production directory often offers both.

### Bring up the 636 listener

On Debian and Ubuntu, `slapd`'s list of listening addresses is the `SLAPD_SERVICES` line in `/etc/default/slapd`. Look at it, add `ldaps:///`, restart, and check the ports:

<!-- astrona:playground:renew -->

```sh
grep SLAPD_SERVICES /etc/default/slapd
sudo sed -i 's|^SLAPD_SERVICES=.*|SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"|' /etc/default/slapd
sudo systemctl restart slapd
sudo ss -tlnp | grep -E ':389|:636'
```

Expect something like:

```text
SLAPD_SERVICES="ldap:/// ldapi:///"
LISTEN 0 1024 *:389 *:* users:(("slapd",pid=1200,fd=8))
LISTEN 0 1024 *:636 *:* users:(("slapd",pid=1200,fd=9))
```

Before the edit, only `ldap:///` and `ldapi:///` were listed. After it, `636` joins `389` in the `ss` output. A typo in `SLAPD_SERVICES` would stop `slapd` from starting; check `systemctl status slapd` if `636` is missing.

### Three listeners, three jobs

Each address in `SLAPD_SERVICES` has one job:

- `ldap:///`: port 389, plain or upgraded with StartTLS.
- `ldaps:///`: port 636, native TLS.
- `ldapi:///`: the local socket you use to administer `cn=config`.

## Verify the certificate and LDAP connection

Configure the client to trust the training certificate before testing. The server's `olcTLSCACertificateFile` setting does not configure client trust.

```sh
sudo tee /etc/ldap/ldap.conf >/dev/null <<'EOF'
TLS_CACERT /etc/ldap/certs/ldap-server.crt
TLS_REQCERT demand
EOF
```

Check certificate verification and the LDAP operation separately.

### The transport layer: `openssl s_client`

`openssl s_client` is OpenSSL's built-in TLS *client*. It opens a raw encrypted connection to a host and port, prints the certificate the server presents and the handshake result, then waits for input. `</dev/null` gives it no input, so it reports and exits. `-connect host:port` is the target, and `-showcerts` prints the full chain:

```sh
openssl s_client -connect 127.0.0.1:636 -showcerts -CAfile /etc/ldap/certs/ldap-server.crt -verify_ip 127.0.0.1 -verify_return_error </dev/null
```

Require `Verify return code: 0 (ok)`. The supplied certificate is the trust anchor in this sandbox, and `-verify_ip` checks the IP subject alternative name. A self-signed certificate error means the client has not established trust.

### The LDAP layer: `ldapsearch -ZZ`

The second question is whether StartTLS really negotiates through `slapd`:

```sh
ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base
```

`-x` is a simple bind. `-b "" -s base` reads only the root DSE, a tiny entry that always exists. `-ZZ` *requires* StartTLS to succeed before the search runs, and stops with an error otherwise. So any result here is real proof that the encrypted upgrade worked from end to end.

If the verified connection on port 636 succeeds but StartTLS fails, inspect the LDAP client trust settings and the server logs. The two commands use different TLS clients and connection paths.

### Both layers, in order

Run a short version of both checks:

```sh
openssl s_client -connect 127.0.0.1:636 -CAfile /etc/ldap/certs/ldap-server.crt -verify_ip 127.0.0.1 -verify_return_error </dev/null 2>/dev/null | grep -E 'subject=|Verify return code'
ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base namingContexts
```

Expect something like:

```text
subject=CN = localhost
Verify return code: 0 (ok)
dn:
namingContexts: dc=example,dc=com
```

The connection on port 636 verifies the trusted certificate and its IP address. The `-ZZ` search forced a StartTLS upgrade on 389 and still returned the root DSE. Its `namingContexts` repeats the base DN you set. The server is installed, serves `dc=example,dc=com`, is proven on both TLS paths, and is completely empty.

> [!TIP]
> Always prove TLS at both layers. `openssl s_client` shows the badge and the handshake; `ldapsearch -ZZ` shows that LDAP itself really runs over the sealed channel.

## Common pitfalls

> [!WARNING]
> - **A typo in `SLAPD_SERVICES`.** `slapd` will not start. `systemctl status slapd` and `journalctl -u slapd` show why.
> - **Treating `openssl s_client` success as full proof.** It only proves the transport. `ldapsearch -ZZ` proves that StartTLS negotiates through `slapd`.
> - **Accepting an unverified handshake.** Return code 18 means trust failed. Supply the lab trust anchor and require successful verification.
> - **Using `-Z` to prove encryption.** A single `-Z` falls back to plain text if StartTLS fails. Only `-ZZ` proves it.

## Your mission: OpenLDAP Server Install & TLS Lab

You can now name a registry, give it a hashed administrator password, wire in its certificate and prove both TLS paths. Now prove it in a graded mission: a fresh ship with `slapd` installed and a certificate waiting, where you set up the base DN, the administrator and both listeners.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ldap-server-tls-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-041
```

Open a terminal on the mission ship:

```sh
astrona ssh ats-005-lab-041
```

Read the task in [`question.md`](../../../labs/lab-041/docs/question.md) and solve it on your own first. When you think you are done, send it for grading from your own computer:

```sh
astrona submit -c labs/lab-041
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-005-lab-041
astrona start ldap-server-tls-playground
```
