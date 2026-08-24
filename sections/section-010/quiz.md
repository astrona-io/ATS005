# Section 010 Knowledge Check: Local Account & Group Lifecycle

Test your understanding of primary vs. supplementary groups, scoped sudo rules, group lifecycle management, and password/account aging.

---

## Scenario-Based Questions

### Question 1
You run `sudo usermod -g dev -d /home/accounts/user1 user1` (no other flags) to move `user1` to a new home directory and primary group. Afterward, `getent passwd user1` shows the new home path, but `ls /home/accounts/user1` shows the directory is empty, while `user1`'s old files are still sitting at the original path. What went wrong?
*   **A)** `usermod -g` does not support changing the home directory at the same time as the group.
*   **B)** The `-m` flag was omitted, so only the `/etc/passwd` pointer was updated — the file contents were never moved.
*   **C)** `user1` did not have permission to own files in the new directory.
*   **D)** `usermod` requires the target directory to be empty before it will populate it.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `usermod -d` only rewrites the home-directory field in `/etc/passwd`. The `-m` (`--move-home`) flag is what actually copies the old home directory's contents into the new path, and it only takes effect when combined with `-d`. Without it, the account's passwd record points somewhere new while every file stays behind at the old location.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — `usermod` happily accepts `-g` and `-d` (and `-m`) together in a single invocation.
    *   *Option C* is incorrect — ownership/permission errors would produce explicit error output, not a silently empty directory.
    *   *Option D* is incorrect — `usermod -m` creates and populates the target leaf directory itself; it does not require it to pre-exist.
</details>

---

### Question 2
An existing user, `analyst4`, already belongs to groups `finance` and `reporting` in addition to their primary group. You need to add them to a new group, `audit-ro`, without affecting anything else. Which command is correct?
*   **A)** `sudo usermod -G audit-ro analyst4`
*   **B)** `sudo usermod -aG audit-ro analyst4`
*   **C)** `sudo groupadd -G audit-ro analyst4`
*   **D)** `sudo useradd -G audit-ro analyst4`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `-aG` (append) adds the named group to the user's existing supplementary group list without disturbing any group already there. This is the only safe form for adding one group to an *existing* account.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — plain `-G` (no `-a`) **replaces** the entire supplementary group list with exactly what's given, silently dropping `finance` and `reporting`.
    *   *Option C* is incorrect — `groupadd` creates groups; it has no such flag and doesn't operate on user accounts.
    *   *Option D* is incorrect — `useradd` only creates brand-new accounts; running it against an existing username fails outright.
</details>

---

### Question 3
You need `user2` to run `sudo bash /root/dangerous.sh` with no password prompt, and nothing else. You add this line via `visudo -f /etc/sudoers.d/user2-script`:
```
user2 ALL=(root) NOPASSWD: /root/dangerous.sh
```
When `user2` actually runs `sudo bash /root/dangerous.sh`, they are still prompted for a password. Why?
*   **A)** The sudoers rule authorizes running `/root/dangerous.sh` directly as its own command, but the user is invoking `bash` with the script as an argument — a different command entirely from sudoers' point of view.
*   **B)** `NOPASSWD` rules only ever apply to the `root` user itself.
*   **C)** The drop-in file needs a `.sudoers` file extension to be read.
*   **D)** `visudo -f` does not actually save changes to disk.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** sudoers command matching is literal, including the invoked binary. The rule as written only matches a direct `sudo /root/dangerous.sh` invocation (relying on the script's shebang and execute bit). Since the user actually runs `sudo bash /root/dangerous.sh`, the authorized command must be the resolved `bash` binary's path plus that exact argument, e.g. `/usr/bin/bash /root/dangerous.sh`.
*   **Why others are incorrect:**
    *   *Option B* is incorrect — `NOPASSWD` can be scoped to any user or group sudoers grants a rule to.
    *   *Option C* is incorrect — files under `/etc/sudoers.d/` are read regardless of extension (as long as they don't match the backup-file exclusion patterns like a trailing `~` or `.rpmnew`).
    *   *Option D* is incorrect — `visudo -f <path>` does save the file; it only refuses to save if the syntax is invalid.
</details>

---

### Question 4
You need to create a group named `datateam` with GID exactly `5000`, because other systems already expect that number. Which command guarantees this?
*   **A)** `sudo groupadd datateam` followed by manually editing `/etc/group` to change the GID afterward.
*   **B)** `sudo groupadd -g 5000 datateam`
*   **C)** `sudo groupadd -r datateam`
*   **D)** `sudo useradd -g 5000 datateam`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `groupadd -g <GID>` pins the exact GID at creation time. Without `-g`, `groupadd` assigns the next available GID from the range in `/etc/login.defs`, which is not guaranteed to be `5000`.
*   **Why others are incorrect:**
    *   *Option A* would work but is needlessly risky and manual compared to the built-in flag designed for exactly this.
    *   *Option C* is incorrect — `-r` requests a *system* group from the low GID range; it does not pin an arbitrary exact GID like `5000`.
    *   *Option D* is incorrect — `useradd` creates user accounts, not groups, and has no such usage.
</details>

---

### Question 5
An account `contractor3` needs to be immediately barred from authenticating with a password, without deleting the account or losing its existing password so it can be restored later. Which command is correct, and what does it actually do at the data level?
*   **A)** `sudo userdel contractor3` — removes the account entirely; it can be recreated later with the same username.
*   **B)** `sudo passwd -l contractor3` — prefixes the encrypted password field in `/etc/shadow` so it can never match input, without erasing the original hash.
*   **C)** `sudo chage -M 0 contractor3` — sets the maximum password age to zero, deleting the password.
*   **D)** `sudo usermod -s /usr/sbin/nologin contractor3` — the only correct way to lock any account.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `passwd -l` (equivalently `usermod -L`) prepends a marker to the encrypted password field in `/etc/shadow`. The stored hash is preserved but can never successfully match any password entered — unlocking with `passwd -u` restores the exact original password, not a blank one.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — deletion is permanent and destroys the account's configuration; it's not a reversible "lock."
    *   *Option C* is incorrect — password aging fields govern how long a password is valid; they do not clear or scramble the password hash itself.
    *   *Option D* is incorrect — disabling the login shell blocks interactive shell sessions but is a different, complementary layer to password locking, not a substitute for it, and doesn't affect e.g. `su -c` or key-based non-shell operations the same way.
</details>
