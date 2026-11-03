# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module turned a bare `slapd` into a named, TLS-sealed fleet registry that is ready to be filled.

**From [The Configuration Is A Tree](./course-01-the-configuration-is-a-tree.md):**

- Modern OpenLDAP keeps its configuration as entries under `cn=config`, not in a `slapd.conf` file.
- You change it with an LDIF file and `ldapmodify -Y EXTERNAL -H ldapi:///`, as `root` over the local socket.
- The `ldap*` tools share their options: `-H`, `-x`, `-D`, `-W`, `-Y`, `-Z` and `-ZZ`.

**From [Naming The Directory And Its Administrator](./course-02-naming-the-directory.md):**

- `olcSuffix`, `olcRootDN` and `olcRootPW` on `olcDatabase={1}mdb,cn=config` set the base DN and the administrator.
- `slappasswd` makes the `{SSHA}` hash; a plaintext `olcRootPW` is a leak.

**From [Giving The Server Its Certificate](./course-03-giving-the-server-its-certificate.md):**

- `slapd` runs as `openldap`, so that account must be able to read the key (owner `openldap`, mode `640`).
- `olcTLSCertificateFile`, `olcTLSCertificateKeyFile` and `olcTLSCACertificateFile` go on `cn=config`, and need a restart.

**From [Opening Port 636 And Proving TLS](./course-04-opening-port-636-and-proving-tls.md):**

- StartTLS seals a port 389 connection partway through; LDAPS on 636 is sealed from the first byte.
- `SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"` in `/etc/default/slapd` opens 636.
- Prove TLS with `openssl s_client` (transport) and `ldapsearch -ZZ` (LDAP).

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [OpenLDAP Server Install & TLS Lab](../../../labs/lab-041/docs/question.md) | Opening Port 636 And Proving TLS | set the base DN, administrator and hashed password through `cn=config`, wired in TLS, and opened ports 389 and 636 |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Where does modern OpenLDAP keep its running configuration?</summary>

In the `cn=config` tree: configuration stored as directory entries, changed with LDIF and `ldapmodify`. There is no `slapd.conf` on a modern install.
</details>

<details>
<summary>2. What does <code>-Y EXTERNAL -H ldapi:///</code> mean?</summary>

Authenticate with your operating system identity over the local UNIX socket, instead of a bind DN and password. Run as `root`, it gives you administrator access to `cn=config`.
</details>

<details>
<summary>3. Why must <code>olcRootPW</code> hold a hash from <code>slappasswd</code>?</summary>

LDIF files get copied, pasted and committed. A plaintext password in one is a permanent leak; a salted hash is not.
</details>

<details>
<summary>4. TLS fails at startup, and the error mentions the certificate. What else should you check?</summary>

Whether the `openldap` account can read the private key. `slapd` does not run as `root`.
</details>

<details>
<summary>5. What is the difference between StartTLS and LDAPS?</summary>

StartTLS starts a plain connection on port 389 and upgrades it to TLS. LDAPS on port 636 is encrypted from the first byte.
</details>

<details>
<summary>6. Why prove TLS with <code>ldapsearch -ZZ</code> and not only with <code>openssl s_client</code>?</summary>

`openssl s_client` only proves the transport handshake. `ldapsearch -ZZ` requires StartTLS through `slapd` itself and fails if it does not negotiate.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy ldap-server-tls-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-041
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-040/module-01/playground`. It always starts clean, so nothing you broke carries over.

> *`slapd` running is not the same as TLS working: prove the handshake, then call the registry ready.*
