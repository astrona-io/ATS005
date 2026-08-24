# LFCS Users and Groups Domain Certification Quiz

Welcome to the Final Domain Certification Quiz for the **LFCS Users and Groups** curriculum. This comprehensive test contains **20 high-signal, scenario-based system administration questions** covering all 10 modules inside our 4 sections.

To simulate actual Linux Foundation exam pressure:
*   Answer all 20 questions without consulting external documentation or manual shell helpers.
*   Allow yourself a maximum of **30 minutes** to complete the entire test.
*   Once finished, scroll to the very bottom to check the **Audit and Review Key** to trace any incorrect answers back to their exact section and module chapters.

---

## The Exam Simulator

### Question 1
You run `sudo usermod -g finance -d /home/accounts/bob -m bob` to move `bob` into the `finance` group and relocate his home directory. The command completes with no errors. What is the state of `bob`'s old home directory's files immediately afterward?
*   **A)** They are copied to the new path, and the old path still exists with the originals untouched.
*   **B)** They are moved to the new path, and the old directory is gone; but files `bob` already owned elsewhere on disk still show his old group, since `usermod -g` only rewrites the GID field in `/etc/passwd`.
*   **C)** They remain in the old path; `usermod` only ever rewrites text fields in `/etc/passwd` and never touches the filesystem, even with `-m`.
*   **D)** They are deleted entirely, since `-m` without `-d` is required to preserve file contents.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `-m` (`--move-home`) is what actually copies the old home directory's contents to the new path and removes the old directory once combined with `-d`. But `-g` only changes the primary GID field in `/etc/passwd` — it is never retroactive against existing file ownership elsewhere on disk. Any files `bob` already owned under his old group keep that group until explicitly `chown`/`chgrp`'d.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because `-m` moves (not copies) the directory — the old path does not survive.
    *   *Option C* is incorrect because `-m` specifically exists to move file contents; without it, only the passwd record would change.
    *   *Option D* is incorrect because `-m` combined with `-d` is exactly the safe, documented way to relocate a home directory without losing data.
</details>

---

### Question 2
You need `user2` to run `sudo bash /root/dangerous.sh` with no password prompt, and nothing else. Which `/etc/sudoers.d/` entry correctly satisfies this with least privilege?
*   **A)** `user2 ALL=(ALL) NOPASSWD: ALL`
*   **B)** `user2 ALL=(root) NOPASSWD: /root/dangerous.sh`
*   **C)** `user2 ALL=(root) NOPASSWD: /usr/bin/bash /root/dangerous.sh`
*   **D)** `user2 ALL=(root) PASSWD: /usr/bin/bash /root/dangerous.sh`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** `sudoers` command matching is literal, including the invoked form. The user runs `sudo bash /root/dangerous.sh`, meaning the executed binary is `bash` (resolved to its absolute path) with the script as an argument — not the script executed directly via its own shebang. The rule must authorize exactly that invocation, and `NOPASSWD` is required since no password should be prompted.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because it grants unlimited root access to any command — a severe over-grant far beyond the task.
    *   *Option B* is incorrect because it only matches `sudo /root/dangerous.sh` run directly, not `sudo bash /root/dangerous.sh` — the invoked command differs from what's authorized.
    *   *Option D* is incorrect because `PASSWD` (or omitting a tag, which defaults to requiring one) would still prompt for a password, failing the "no password" requirement.
</details>

---

### Question 3
You run `sudo groupadd datateam` with no other flags. Where does the resulting GID come from?
*   **A)** It is always `1000`, the standard first user GID on every distribution.
*   **B)** `groupadd` assigns the next available GID at or above the range configured in `/etc/login.defs` (e.g. `GID_MIN`/`GID_MAX`), skipping any already in use.
*   **C)** It is randomly generated to avoid collisions across a fleet of machines.
*   **D)** `groupadd` refuses to run without an explicit `-g`, so the command above would fail.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Without `-g`, `groupadd` consults `/etc/login.defs` for the configured GID range and picks the next free number in that range — the same mechanism `useradd` uses for UIDs. This is exactly why a task that requires an *exact* GID (like `5000`) must pass `-g 5000` explicitly rather than relying on the default.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because `1000` is a common first *user* UID/GID convention on some distros, not a fixed rule `groupadd` follows for every new group.
    *   *Option C* is incorrect because GID assignment is deterministic (next available in range), not random.
    *   *Option D* is incorrect because `-g` is optional; `groupadd` works fine without it.
</details>

---

### Question 4
You rename group `legacy-ops` (GID `4200`) to `platform-ops` with `sudo groupmod -n platform-ops legacy-ops`. A file on disk was previously `chown`'d to `legacy-ops` by name. After the rename, what does `ls -l` show as that file's group?
*   **A)** `platform-ops` — the new name, because `groupmod -n` only changes the name, not the GID, and `ls -l` resolves the file's stored GID against `/etc/group` at display time.
*   **B)** `legacy-ops` — file ownership is permanently locked to the name at the time of `chown` and does not follow renames.
*   **C)** A numeric GID like `4200`, because renaming a group always orphans every file that referenced the old name.
*   **D)** `nobody`, because the rename invalidates the old name and the kernel falls back to the unknown-owner placeholder.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** Files on disk store ownership as a numeric GID, never a name. `ls -l` looks up that number against `/etc/group` every time it displays output. `groupmod -n` changes only the name field for GID `4200`, leaving the GID itself untouched — so any file already tagged with GID `4200` instantly displays under the new name with zero `chown`/`chgrp` needed.
*   **Why others are incorrect:**
    *   *Option B* is incorrect because file ownership is GID-based, not name-based, so it does follow a rename automatically.
    *   *Option C* is incorrect — a rename alone does not change the GID, so nothing becomes orphaned by this operation (orphaning only happens if the GID itself is deleted or changed, as `groupdel`'s man page warns).
    *   *Option D* is incorrect because `nobody` only appears when a GID has **no** corresponding entry in `/etc/group` at all, which isn't the case here.
</details>

---

### Question 5
You just added `marta` to the `datateam` group with `sudo usermod -aG datateam marta`. Marta already had an open terminal session before you ran this. She immediately runs `id` in that same session. What do you expect?
*   **A)** `datateam` will not appear in her `groups=` list, because group membership is only evaluated fresh at login/session start, not retroactively into an already-running shell.
*   **B)** `datateam` appears immediately, because `/etc/group` is polled continuously by every running shell.
*   **C)** `id` always shows live membership regardless of session age, unlike `groups`, which is the one that lags.
*   **D)** Marta's session will be forcibly terminated the moment her group memberships change.
<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** A user's supplementary group list is computed once at login (or session start) and cached in that session's process credentials. `/etc/group` being updated afterward doesn't retroactively push into already-running shells. Marta needs a new session (fresh login, new SSH connection, or `newgrp`) — or `su - marta` — to see `datateam` reflected.
*   **Why others are incorrect:**
    *   *Option B* is incorrect — there is no continuous polling of `/etc/group` by running shells.
    *   *Option C* is incorrect — both `id` and `groups` read the same cached session credentials; neither is "live" mid-session.
    *   *Option D* is incorrect — changing group membership has no effect on already-running sessions at all, let alone terminating them.
</details>

---

### Question 6
You create `contractor7` with `sudo useradd -m contractor7` (no `-s`/`-b` overrides) and want to confirm the shell and home base path it actually received before assuming anything. Which command reveals the *system's configured defaults* directly, without guessing?
*   **A)** `cat /etc/passwd | grep contractor7`
*   **B)** `useradd -D`
*   **C)** `sudo chage -l contractor7`
*   **D)** `id contractor7`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `useradd -D` prints the exact defaults `useradd` pulls from `/etc/default/useradd` (and consults alongside `/etc/login.defs`) — default shell, home base directory, default group behavior, and account inactivity/expire defaults — before you ever create an account, or to audit what a plain `useradd` call actually used.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because it shows what was *actually assigned* to one already-created account, not the *configured defaults* the question asks to confirm independently.
    *   *Option C* is incorrect — `chage -l` reports password/account aging fields, not shell or home base path defaults.
    *   *Option D* is incorrect — `id` reports UID/GID/groups, not shell or home directory defaults.
</details>

---

### Question 7
You need `contractor7`'s account (not just their password) to stop working entirely, automatically, in exactly 30 days. Which `chage` flag accomplishes this?
*   **A)** `chage -M 30 contractor7` — sets the maximum password age to 30 days.
*   **B)** `chage -E $(date -d "+30 days" +%Y-%m-%d) contractor7` — sets the account expiration date.
*   **C)** `chage -d 0 contractor7` — forces a password reset at next login.
*   **D)** `chage -I 30 contractor7` — sets a 30-day inactivity lock after password expiry.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `-E` (`--expiredate`) sets the account's own expiration date — after which the account itself is completely unusable, independent of password state. This is distinct from password *expiry* (`-M`), which only forces a password change but leaves the account active.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — `-M` controls password expiry cadence, not whether the whole account stops working.
    *   *Option C* is incorrect — `-d 0` forces an immediate password change at next login, unrelated to a 30-day account-level expiration.
    *   *Option D* is incorrect — `-I` sets a grace/inactivity period counted *after* the password already expired, not a direct 30-day account expiration.
</details>

---

### Question 8
A shared directory `/srv/projects/orion` is owned `team-lead:orion-team`, mode `750`. Contractor `contractor-jane` (not a member of `orion-team`) needs read-write access to the entire tree, and should never be added to the group. Which approach satisfies this correctly?
*   **A)** `sudo usermod -aG orion-team contractor-jane`
*   **B)** `sudo chmod -R 770 /srv/projects/orion`
*   **C)** `sudo setfacl -R -m u:contractor-jane:rwx /srv/projects/orion`
*   **D)** `sudo chown -R contractor-jane /srv/projects/orion`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** POSIX ACLs let you grant a specific extra user rights on a file or directory tree without altering group membership, ownership, or the standard permission bits. `setfacl -R -m u:contractor-jane:rwx` grants exactly that, recursively, while `orion-team`'s membership and `team-lead`'s ownership stay untouched.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because it explicitly violates the "never add her to the group" constraint.
    *   *Option B* is incorrect because widening the group-bit to `770` grants write to *every* `orion-team` member, not just Jane, and still doesn't cover her since she isn't in the group.
    *   *Option D* is incorrect because changing ownership displaces `team-lead` as the file owner entirely, which is destructive and unnecessary.
</details>

---

### Question 9
You've run `setfacl -m u:auditor-tom:r-x /srv/projects/orion` on an existing directory tree, but new files created inside it afterward do not carry Tom's read access automatically. What's missing?
*   **A)** A recursive `chmod -R` needs to be run after every new file is created.
*   **B)** A **default ACL** entry (`setfacl -d -m u:auditor-tom:r-x /srv/projects/orion`) needs to be set on the directory so newly created files/subdirectories inherit the same entry automatically.
*   **C)** ACLs never apply to files created after the `setfacl` command runs; they must be re-applied by hand every time, permanently.
*   **D)** The `orion-team` group's GID needs to be added to the mask entry.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A plain `setfacl -m` entry only applies to the objects that exist at the time it's run. A **default** ACL (the `-d` flag) is a separate, inheritable rule attached to the directory itself — every new file or subdirectory created afterward automatically picks up a matching regular ACL entry at creation time, with no manual re-application needed.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — that would be a manual, error-prone workaround; default ACLs exist specifically to avoid it.
    *   *Option C* is incorrect — ACLs absolutely can apply automatically to future files, that's exactly what default ACLs are for.
    *   *Option D* is incorrect — the mask entry caps effective permissions for named entries, it does not control inheritance to new files.
</details>

---

### Question 10
A user's process-count limit was set with `ulimit -H -u 200` inside their personal `~/.bashrc`. A coworker reports the limit "doesn't apply" when the same user's jobs are launched via `cron`. Why?
*   **A)** `cron` jobs always run as root, bypassing all user-level limits.
*   **B)** `.bashrc` is only sourced by interactive, non-login shells — `cron`-launched processes never source it, so the limit was never actually enforced outside that one shell type.
*   **C)** `ulimit -H` only applies to soft limits, and cron respects only hard limits.
*   **D)** `cron` ignores all `nproc` limits by design, regardless of where they're configured.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A `ulimit` command inside `.bashrc` only takes effect for shells that actually source that file — interactive, non-login shells. `cron` jobs, `systemd`-launched services, and `su` without a login shell never source `.bashrc`, so the limit silently doesn't apply there. The system-wide, PAM-enforced mechanism (`/etc/security/limits.conf` + `pam_limits.so`) is required for a limit to apply regardless of how the session started.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — cron jobs run as the crontab owner by default, not automatically as root.
    *   *Option C* is incorrect — `-H` explicitly sets the hard limit; the issue is the file never gets sourced, not a soft/hard mismatch.
    *   *Option D* is incorrect — cron does respect `nproc` limits when they're actually applied through a mechanism it participates in, like PAM.
</details>

---

### Question 11
You need every member of the `operators` group capped at exactly one concurrent login system-wide, enforced no matter how they connect. Which line belongs in `/etc/security/limits.conf`?
*   **A)** `operators hard maxlogins 1`
*   **B)** `@operators - maxlogins 1`
*   **C)** `@operators hard maxlogins 1`
*   **D)** `*  soft  maxlogins 1`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** The `@groupname` syntax targets every member of a group as the domain. `maxlogins` is inherently a hard-style cap on concurrent sessions (not something meaningfully split into soft/hard nuance for this specific item in the way process/file limits are), and `hard` is the conventional, unambiguous choice to guarantee it's enforced as a strict ceiling for the whole group.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — without the `@` prefix, `operators` is parsed as a literal *username*, not a group.
    *   *Option B* is incorrect — `-` sets both soft and hard identically, which can work, but doesn't match the documented, exam-expected hard-limit convention for this exact competency as clearly as `hard` does.
    *   *Option D* is incorrect — `*` applies to every user on the system, not specifically the `operators` group.
</details>

---

### Question 12
The infrastructure team needs `COMPANY_PROXY=http://proxy.internal:3128` available to **every** user, for both login *and* non-login interactive shells, without editing any individual user's dotfiles. Which file is the correct system-wide mechanism for this specific requirement?
*   **A)** `/etc/profile.d/company-proxy.sh`, since `.sh` scripts under `profile.d` are sourced for every shell type.
*   **B)** `/etc/environment`, since PAM parses and exports it into every user's session environment regardless of shell type or login/non-login distinction.
*   **C)** `~/.bashrc` for each existing user, copied manually.
*   **D)** `/etc/skel/.bashrc`, so it only affects accounts created afterward.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `/etc/environment` is parsed by `pam_env` at session-open time (not sourced as a shell script), which is exactly why it reaches every session type uniformly — login and non-login, interactive and not — without depending on which shell dotfiles a particular session happens to source.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — `/etc/profile.d/*.sh` scripts are only sourced by `/etc/profile`, which fires for **login** shells; a non-login interactive shell that only sources `~/.bashrc` never reaches them.
    *   *Option C* is incorrect — this is exactly the fragile per-user editing the "without editing any individual user's dotfiles" requirement rules out, and it wouldn't cover future accounts either.
    *   *Option D* is incorrect — `/etc/skel` only seeds new accounts' home directories at creation time; it has zero effect on existing accounts.
</details>

---

### Question 13
User `candidate` wants `~/work` on their `PATH` so their personal scripts run by name, but a script in `~/work` must **never** override an existing system command of the same name. Which change satisfies this?
*   **A)** `export PATH="$HOME/work:$PATH"` in `~/.bash_profile`
*   **B)** `export PATH="$PATH:$HOME/work"` in `~/.bash_profile`
*   **C)** `export PATH="$HOME/work:$PATH"` in `~/.bashrc` only
*   **D)** `alias work='cd ~/work'` in `~/.bash_profile`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `PATH` is searched left to right, first match wins. **Appending** `~/work` after the existing `$PATH` guarantees any system command of the same name (found earlier in the existing path entries) is resolved first — a same-named script in `~/work` can never shadow it. Placing it in `~/.bash_profile` (a login-shell dotfile) also makes the change persistent across new sessions.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — **prepending** `~/work` means anything placed there is found *before* system directories, meaning a maliciously or accidentally named script (`ls`, `sudo`, etc.) would run instead of the real command — a privilege-escalation risk, and the opposite of "never shadow."
    *   *Option C* is incorrect for the same prepend reasoning, and additionally `.bashrc` alone doesn't reliably cover every session type a login shell would.
    *   *Option D* is incorrect — an alias to `cd` does nothing to make scripts inside `~/work` runnable by name from anywhere.
</details>

---

### Question 14
Right after editing `~/.bash_profile` to change `PATH`, you run `echo $PATH` in your *current* terminal and see no change at all. Why, and what's the correct next step?
*   **A)** The edit failed silently; re-open the file and check for a typo.
*   **B)** Dotfile edits only take effect for *new* shells that source that file — your current shell already has its environment loaded and won't re-read the file until a new login shell starts (or you explicitly re-source it).
*   **C)** `PATH` changes require a full system reboot to take effect.
*   **D)** `bash` caches `PATH` permanently at install time; only `type` and `which` reflect live changes.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Shell dotfiles are only read when a matching new shell session starts. An already-running shell already evaluated `~/.bash_profile` once at its own startup and holds that environment in memory — it has no reason to re-read the file afterward. Opening a fresh login shell (or `source ~/.bash_profile` in the current one) is what surfaces the change.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — this is expected, normal shell behavior, not a sign of failure.
    *   *Option C* is incorrect — a reboot is unnecessary; a new shell session is sufficient.
    *   *Option D* is incorrect — `bash` does not permanently cache `PATH` at install time; it reads dotfiles fresh at each new shell's startup.
</details>

---

### Question 15
You are provisioning a brand-new OpenLDAP server. Which statement about its configuration model is accurate on a modern installation?
*   **A)** All configuration lives in a single flat `/etc/ldap/slapd.conf` file, edited directly with a text editor.
*   **B)** Configuration lives in the `cn=config` dynamic backend — a live directory tree of its own, modified via LDIF operations (e.g. `ldapmodify`) against the running server, not a flat text file.
*   **C)** OpenLDAP has no persistent configuration; every setting must be passed as a `slapd` command-line flag at every startup.
*   **D)** TLS certificate paths can only be set by recompiling `slapd` from source with the paths hardcoded.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Modern OpenLDAP replaced the legacy flat `slapd.conf` with the `cn=config` dynamic configuration backend — configuration is itself directory data, changed live via LDIF `ldapmodify` operations (commonly authenticated with `-Y EXTERNAL` over the `ldapi:///` local socket), without needing to restart `slapd` for most changes.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — that describes the legacy model modern OpenLDAP moved away from.
    *   *Option C* is incorrect — `cn=config` is exactly the persistent configuration store; nothing needs to be repeated as command-line flags at every start.
    *   *Option D* is incorrect — TLS paths are set via `olcTLSCertificateFile`/`olcTLSCertificateKeyFile`/`olcTLSCACertificateFile` attributes modified through `cn=config`, no recompilation involved.
</details>

---

### Question 16
After wiring TLS into your OpenLDAP server, which command sequence most directly proves that an actual encrypted handshake succeeds, as opposed to merely confirming the configuration was saved?
*   **A)** `cat /etc/ldap/slapd.d/cn=config/olcDatabase*/olcTLSCertificateFile.ldif`
*   **B)** `sudo systemctl status slapd`
*   **C)** `ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base` (or `openssl s_client -connect 127.0.0.1:636`)
*   **D)** `ss -tlnp | grep 636`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** `-ZZ` forces `ldapsearch` to require StartTLS and abort if the negotiation fails, actually exercising the encrypted handshake rather than just reaching the server. `openssl s_client` against port 636 similarly performs and reports a live TLS negotiation. Both prove the handshake actually works, not just that a config value exists.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — this only shows that a certificate path was *saved* in configuration, not that TLS actually negotiates successfully at runtime.
    *   *Option B* is incorrect — a running daemon doesn't confirm TLS is correctly wired; `slapd` can be "active" while TLS is completely broken.
    *   *Option D* is incorrect — a listening socket on 636 confirms the port is open, not that a TLS handshake against it actually completes.
</details>

---

### Question 17
You add a new POSIX user via LDIF with `objectClass: posixAccount`. Which set of attributes is *required* for this object class (the exact fields NSS/`sssd` will later read on a client)?
*   **A)** `mail`, `telephoneNumber`, `displayName`
*   **B)** `uidNumber`, `gidNumber`, `homeDirectory`, `loginShell`
*   **C)** `member`, `ou`, `description`
*   **D)** `cn`, `sn` only

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `posixAccount` requires `uidNumber` (numeric UID), `gidNumber` (primary GID), `homeDirectory`, and (in practice) `loginShell` to behave as a usable Unix account — these are exactly the same fields NSS/`sssd` consult client-side to resolve the account as if it were a local `/etc/passwd` entry.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — those are `inetOrgPerson`-style contact attributes, not what makes an entry a usable POSIX account.
    *   *Option C* is incorrect — `member` belongs to group object classes like `groupOfNames`, not `posixAccount`.
    *   *Option D* is incorrect — `cn`/`sn` are naming attributes from `person`-family object classes, not the POSIX-specific UID/GID/home/shell fields this question asks about.
</details>

---

### Question 18
After setting `lfcsuser`'s password, which single command most cleanly proves an authenticated bind as that user succeeds, without the added complexity of interpreting search results?
*   **A)** `ldapsearch -x -b "dc=example,dc=com" "(uid=lfcsuser)"`
*   **B)** `ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -w '<password>' -H ldap://127.0.0.1 -Z`
*   **C)** `slappasswd -s '<password>'`
*   **D)** `getent passwd lfcsuser`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `ldapwhoami` performs the "Who am I?" extended LDAP operation — it authenticates with the given bind DN and password and simply confirms identity, with no search results to parse. It's the cleanest possible proof that a specific bind DN/password combination is valid over the given connection (here, requiring StartTLS via `-Z`).
*   **Why others are incorrect:**
    *   *Option A* is incorrect — an anonymous or admin-bound search can locate the entry without ever proving `lfcsuser`'s own password is correct.
    *   *Option C* is incorrect — `slappasswd` only generates a password hash locally; it never contacts the directory or proves a bind works.
    *   *Option D* is incorrect — `getent` queries local NSS sources (only meaningful client-side after `sssd`/NSS is wired up), and proves resolution, not an authenticated LDAP bind.
</details>

---

### Question 19
On the LDAP client, you've written `/etc/sssd/sssd.conf` and restarted `sssd`, but `getent passwd lfcsuser` still returns nothing. `sssd.conf` itself looks syntactically correct. What is the most likely single cause?
*   **A)** `sssd.conf` is not `600`, owned `root:root` — `sssd` refuses to start (or silently ignores the file) if permissions are too open.
*   **B)** `nsswitch.conf`'s `passwd`/`group` lines still only list `files`, without `sss` added, so NSS never consults `sssd` at all regardless of how correct `sssd.conf` is.
*   **C)** Both A and B are plausible single causes and should both be checked.
*   **D)** `getent` never works with LDAP-backed accounts under any configuration; only `id` does.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** Either misconfiguration independently breaks resolution: `sssd` demands `sssd.conf` be `600 root:root` or it won't trust (and may refuse to start with) the file at all, and separately, `nsswitch.conf` must list `sss` on the `passwd`/`group` lines or NSS never even asks `sssd` for the answer — a perfectly correct `sssd.conf` is irrelevant if NSS isn't configured to consult it. Both should be checked, in that order (permissions first, since a refused-to-start daemon makes the nsswitch question moot).
*   **Why others are incorrect:**
    *   *Option A* alone is incomplete — it's a valid cause, but not the only one worth checking.
    *   *Option B* alone is incomplete for the same reason in reverse.
    *   *Option D* is incorrect — `getent passwd` fully supports NSS-backed sources including `sss`, and is in fact the recommended first verification step, *before* testing an interactive login.
</details>

---

### Question 20
After successfully wiring `sssd` for LDAP authentication on a client, you want to confirm local accounts are completely unaffected. Which check most directly proves this?
*   **A)** `getent passwd root` still resolves root as UID `0` from the local `files` source, unaffected by whatever state LDAP/`sssd` is in.
*   **B)** `systemctl status sssd` shows "active (running)".
*   **C)** `ldapsearch -x -b "dc=example,dc=com" "(uid=root)"` returns no results.
*   **D)** `id lfcsuser` resolves correctly.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** `nsswitch.conf`'s ordering (`files sss`) means local accounts are always resolved from `/etc/passwd` first, regardless of `sssd`'s health. Directly confirming `root` (or any known-local account) still resolves correctly via `getent` is the most direct proof that adding LDAP as a source didn't disturb local account resolution at all.
*   **Why others are incorrect:**
    *   *Option B* is incorrect — a running `sssd` daemon says nothing about whether local accounts specifically are unaffected.
    *   *Option C* is incorrect — confirming `root` isn't *in LDAP* doesn't prove local resolution of `root` still works; it only shows the directory itself has no such entry, which was never the concern.
    *   *Option D* is incorrect — that proves the LDAP side works, not that local accounts remain unaffected, which is what this question specifically asks to verify.
</details>

---

## Audit and Review Key

Check your score and use this review matrix to trace any incorrect answers back to their exact section and module chapters:

| Question | Targeted Users & Groups Competency | Review Chapter |
| :--- | :--- | :--- |
| **Q1** | `usermod -g/-d/-m` and non-retroactive file ownership | **[Section 010, Module 01](./section-010/module-01/course.md)** |
| **Q2** | Exact-command sudoers matching with `NOPASSWD` | **[Section 010, Module 01](./section-010/module-01/course.md)** |
| **Q3** | `groupadd` default GID assignment from `login.defs` | **[Section 010, Module 02](./section-010/module-02/course.md)** |
| **Q4** | `groupmod -n` rename vs. numeric GID file ownership | **[Section 010, Module 02](./section-010/module-02/course.md)** |
| **Q5** | Group membership caching in already-open sessions | **[Section 010, Module 02](./section-010/module-02/course.md)** |
| **Q6** | Confirming `useradd` defaults with `useradd -D` | **[Section 010, Module 03](./section-010/module-03/course.md)** |
| **Q7** | Account expiry (`chage -E`) vs. password expiry (`chage -M`) | **[Section 010, Module 03](./section-010/module-03/course.md)** |
| **Q8** | Granting one external user access via ACL without group changes | **[Section 020, Module 01](./section-020/module-01/course.md)** |
| **Q9** | Default ACLs for automatic inheritance on new files | **[Section 020, Module 01](./section-020/module-01/course.md)** |
| **Q10** | Why `.bashrc`-based `ulimit` doesn't reach `cron` | **[Section 020, Module 02](./section-020/module-02/course.md)** |
| **Q11** | `@groupname` domain syntax and `maxlogins` in `limits.conf` | **[Section 020, Module 02](./section-020/module-02/course.md)** |
| **Q12** | `/etc/environment` vs. `/etc/profile.d` for system-wide variables | **[Section 030, Module 01](./section-030/module-01/course.md)** |
| **Q13** | Safe PATH extension: append, never prepend | **[Section 030, Module 02](./section-030/module-02/course.md)** |
| **Q14** | Why dotfile edits don't affect the current running shell | **[Section 030, Module 02](./section-030/module-02/course.md)** |
| **Q15** | OpenLDAP's `cn=config` dynamic backend vs. flat `slapd.conf` | **[Section 040, Module 01](./section-040/module-01/course.md)** |
| **Q16** | Verifying a real TLS handshake, not just saved configuration | **[Section 040, Module 01](./section-040/module-01/course.md)** |
| **Q17** | Required `posixAccount` attributes NSS/sssd depend on | **[Section 040, Module 02](./section-040/module-02/course.md)** |
| **Q18** | `ldapwhoami` as the cleanest authenticated-bind proof | **[Section 040, Module 02](./section-040/module-02/course.md)** |
| **Q19** | `sssd.conf` permissions and `nsswitch.conf` wiring, together | **[Section 040, Module 03](./section-040/module-03/course.md)** |
| **Q20** | Confirming local accounts are unaffected by LDAP integration | **[Section 040, Module 03](./section-040/module-03/course.md)** |
