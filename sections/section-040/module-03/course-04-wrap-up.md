# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and clean up anything still running.

## What you learned

This module turned the ship into a client of the fleet registry: `sssd` asks the registry, keeps a short-term copy, and NSS hands the answers to the rest of the system.

**From [Why SSSD](./course-01-why-sssd.md):**

- `sssd` is a daemon with a cache and retries. A direct NSS-to-LDAP setup has neither.
- `libnss-sss` and `libpam-sss` connect the daemon to name lookups and logins.

**From [Writing sssd.conf](./course-02-writing-sssd-conf.md):**

- The `[sssd]` section names the services and domains. A matching `[domain/<name>]` section holds `id_provider`, `auth_provider`, the URI, the search base and the certificate.
- `ldap_id_use_start_tls = true` and `ldap_tls_cacert` give a sealed channel that trusts your server.
- `sssd.conf` must be mode `600` and owned by `root:root`, or `sssd` refuses to start.

**From [Wiring NSS And Checking In Order](./course-03-wiring-nss-and-checking-in-order.md):**

- Add `sss` after `files` on the `passwd` and `group` lines, so local accounts keep winning.
- Check in order: `getent passwd`, `getent group`, `id`, then `root`. Prove lookups before you try a login.

## Your missions

You proved these skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [SSSD LDAP Client Integration Lab](../../../labs/lab-043/docs/question.md) | Wiring NSS And Checking In Order | wrote `sssd.conf`, set its mode, added `sss` to NSS, started `sssd` and resolved `lfcsuser` while `root` stayed intact |

If you skipped it, go back to it now. It is short, and the exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. What does <code>sssd</code> give you that a direct NSS-to-LDAP setup does not?</summary>

A cache, a real daemon and retries. Lookups keep working for a while when the registry is unreachable.
</details>

<details>
<summary>2. Which mode and owner must <code>/etc/sssd/sssd.conf</code> have?</summary>

Mode `600`, owner `root:root`. With looser permissions `sssd` refuses to start.
</details>

<details>
<summary>3. Which two lines of <code>nsswitch.conf</code> get <code>sss</code>?</summary>

`passwd` and `group`, with `sss` after `files`.
</details>

<details>
<summary>4. Why keep <code>files</code> first?</summary>

Local accounts such as `root` resolve from the local files and never depend on the network.
</details>

<details>
<summary>5. Which command checks a user the way the system does?</summary>

`getent passwd <user>`. It walks the whole `nsswitch.conf` chain.
</details>

<details>
<summary>6. Which tool checks the syntax and permissions of <code>sssd.conf</code> without starting the daemon?</summary>

`sssctl config-check`.
</details>

## Clean up the playground

Your playground is a virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy sssd-client-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-005-lab-043
```

Run `astrona list` once more. The playground and the mission should no longer be in the list.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c sections/section-040/module-03/playground`. It always starts clean, so nothing you broke carries over.

> *Prove lookups before logins, and keep `files` first.*
