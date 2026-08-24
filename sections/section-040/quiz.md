# Section 040 Knowledge Check: Centralized Identity with LDAP

Test your understanding of OpenLDAP's `cn=config` backend, TLS wiring, LDIF population, and SSSD client integration.

---

## Scenario-Based Questions

### Question 1
You have just installed `slapd` on a fresh Ubuntu host and need to change the base DN it serves. You open a shell and look for `/etc/ldap/slapd.conf` to edit it directly, but the file either does not exist or has no effect when you change it. What is the correct way to change the base DN on a modern OpenLDAP install?
*   **A)** Edit `/etc/ldap/ldap.conf` instead, which is the modern replacement for `slapd.conf`.
*   **B)** Apply an LDIF `changetype: modify` operation against the appropriate `olcDatabase={N}mdb,cn=config` entry using `ldapmodify -Y EXTERNAL -H ldapi:///`.
*   **C)** Run `sudo systemctl edit slapd` and set the base DN as an environment variable.
*   **D)** Reinstall the `slapd` package and answer the `debconf` prompts differently.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Modern OpenLDAP stores its running configuration as a live, LDAP-queryable tree under `cn=config` (OLC), not a flat text file. Configuration changes are themselves LDAP modify operations, applied as LDIF against the relevant `cn=config` entry — here, the database entry backing directory data — authenticated locally via SASL `EXTERNAL` over the `ldapi:///` socket, which `slapd` trusts as equivalent to root access without a bind password.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because `/etc/ldap/ldap.conf` configures client-side defaults (like `TLS_CACERT`), not the server's own base DN.
    *   *Option C* is incorrect because `slapd` has no concept of reading its base DN from a systemd environment override; base DN is an `olcSuffix` attribute inside `cn=config`.
    *   *Option D* is incorrect because while `dpkg-reconfigure slapd` can re-run the Debian setup wizard, it is not the general mechanism for changing `cn=config`, and reinstalling the package is unnecessary and disruptive compared to a targeted `ldapmodify`.
</details>

---

### Question 2
You configure `olcTLSCertificateFile` and `olcTLSCertificateKeyFile` against `cn=config` and restart `slapd`, but the service fails to come back up. `sudo journalctl -u slapd` shows a TLS initialization error referencing the key file. `ls -l` shows the key is owned `root:root` with mode `600`. What is the most likely cause?
*   **A)** The certificate has expired and must be reissued.
*   **B)** The key file's ownership/permissions prevent `slapd`'s own service account (commonly `openldap`) from reading it, even though `root` can read it fine.
*   **C)** `olcTLSCertificateKeyFile` is the wrong attribute name; it should be `olcTLSPrivateKeyFile`.
*   **D)** `slapd` must be restarted twice for TLS changes to take effect.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `slapd` runs as a dedicated, unprivileged service account (`openldap` on Debian/Ubuntu, often `ldap` on RHEL-family systems), not as `root`. A key file readable only by `root:root` at mode `600` is invisible to that service account, so TLS initialization fails at startup — a permission problem that is easy to misdiagnose as a bad certificate.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because an expired certificate produces a certificate validity error, not a key-file-specific initialization failure, and nothing in the scenario suggests an expiry issue.
    *   *Option C* is incorrect because `olcTLSCertificateKeyFile` is the correct, real attribute name for the private key path.
    *   *Option D* is incorrect; a single restart is sufficient once the underlying file permissions are fixed — the issue described is not a timing problem.
</details>

---

### Question 3
You need to add a new user entry `uid=jdoe,ou=people,dc=example,dc=com` with `ldapadd`, but the operation fails with "No such object." The LDIF file itself has correct syntax with no missing blank lines. What is the most likely cause?
*   **A)** `ldapadd` cannot create `posixAccount` entries; only `ldapmodify` can.
*   **B)** The parent entry `ou=people,dc=example,dc=com` does not exist yet, and LDAP requires parent entries to exist before children can be added beneath them.
*   **C)** The bind DN used does not have a `userPassword` attribute set.
*   **D)** The `uidNumber` attribute value is a duplicate of another entry's `uidNumber`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Unlike a filesystem's `mkdir -p`, LDAP does not implicitly create intermediate parent entries. If `ou=people,dc=example,dc=com` was never created (via its own `organizationalUnit` LDIF entry) before attempting to add a child entry under it, the server correctly rejects the operation with "No such object" — the parent container the new DN depends on simply is not there.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because `ldapadd` (functionally `ldapmodify -a`) can add any valid entry type, including `posixAccount`-classed ones.
    *   *Option C* is incorrect because a missing `userPassword` on the bind DN would produce an authentication failure, not "No such object," and is unrelated to whether the new entry's parent exists.
    *   *Option D* is incorrect because a duplicate `uidNumber` is a data-consistency concern an administrator should catch, not something the LDAP server itself rejects as a constraint violation by default, and it would not produce a "No such object" error in any case.
</details>

---

### Question 4
You run `ldapsearch -x -Z -H ldap://127.0.0.1 -b "dc=example,dc=com" "(uid=lfcsuser)"` and it returns results successfully. You conclude that TLS is definitely working. Why might this conclusion be wrong, and what should you have run instead?
*   **A)** `-Z` requires StartTLS to succeed and abort otherwise, so the conclusion is actually correct as stated.
*   **B)** `-Z` only attempts StartTLS and silently falls back to plaintext if negotiation fails, so success proves nothing conclusive about encryption; `-ZZ` should be used instead, since it aborts on failure.
*   **C)** `ldapsearch` never uses TLS regardless of flags; only `ldapwhoami` can test TLS.
*   **D)** The conclusion is correct, but only because port 636 was used instead of 389.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `-Z` is a "try StartTLS" flag — if negotiation fails for any reason, the client silently continues over the original unencrypted connection instead of erroring out. A successful search with `-Z` therefore does not prove encryption actually happened. `-ZZ` requires the StartTLS upgrade to succeed and aborts the entire operation with an explicit error if it doesn't, making it the only one of the two that constitutes real proof.
*   **Why others are incorrect:**
    *   *Option A* has the behavior of `-Z` backwards — it describes what `-ZZ` does, not `-Z`.
    *   *Option C* is incorrect because `ldapsearch -Z`/`-ZZ` against port 389 (StartTLS) and `-H ldaps://` against port 636 (native LDAPS) both genuinely use TLS; `ldapwhoami` is a useful complementary tool for proving a specific bind credential, not the only tool capable of exercising TLS.
    *   *Option D* is incorrect because the command shown explicitly connects to `ldap://127.0.0.1` on the default port (389), not 636.
</details>

---

### Question 5
On a client running `sssd`, you configure `/etc/sssd/sssd.conf` with a correct `[domain/example.com]` section pointing at a working, populated LDAP server, set the file to `600 root:root`, and start the service successfully. However, `getent passwd lfcsuser` returns nothing. `sudo systemctl status sssd` shows the service active with no errors. What should you check first?
*   **A)** Whether `/etc/nsswitch.conf`'s `passwd` line includes `sss` alongside `files`.
*   **B)** Whether the LDAP server's TLS certificate has expired.
*   **C)** Whether `lfcsuser`'s `uidNumber` in the directory conflicts with a local user's UID.
*   **D)** Whether `cache_credentials = True` is set in `sssd.conf`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** NSS only consults the sources listed on the relevant `nsswitch.conf` line. If the `passwd` line still reads `passwd: files` with no `sss` appended, `getent` never asks SSSD anything at all — regardless of how correctly `sssd.conf` itself is configured or how cleanly the service started. This is the single most common reason a seemingly correct SSSD setup appears to do nothing.
*   **Why others are incorrect:**
    *   *Option B* is incorrect because an expired certificate would typically cause `sssd`'s LDAP connection itself to fail (visible in `sssd` logs or a degraded service state), not a clean "active, no errors" status combined with silently empty `getent` output.
    *   *Option C* is incorrect because a UID conflict would produce an ambiguous or incorrect resolution result at worst, not a completely empty `getent` response, and the scenario doesn't indicate a local account by that name exists.
    *   *Option D* is incorrect because `cache_credentials` affects whether previously-seen users can authenticate during an LDAP outage — it does not control whether NSS is wired to query `sssd` in the first place.
</details>
