# Section 020 Knowledge Check: Access Control & Resource Limits

Test your understanding of POSIX ACLs, default inheritance, the mask entry, and PAM-enforced resource limits.

---

## Scenario-Based Questions

### Question 1
You run `sudo setfacl -m u:contractor-jane:rwx /srv/projects/orion` on a directory that already contains twelve existing files. Afterward, `contractor-jane` cannot open any of those existing files, though `getfacl` on the directory itself shows her entry correctly. What went wrong?
*   **A)** `setfacl` requires `-b` before `-m` to initialize the ACL correctly.
*   **B)** The `-m` flag was never applied without `-R`, so only the directory entry itself was changed — the existing files inside keep their original permissions untouched.
*   **C)** Named-user ACL entries only ever apply to directories, never to regular files.
*   **D)** The mask entry silently blocked the new permission from taking effect on existing files.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `setfacl -m` without `-R` only modifies the ACL of the exact path given on the command line. Files and subdirectories that already exist inside that directory are completely unaffected — they keep whatever permissions they had before. `-R` is required to recursively apply the same ACL entry to every existing file and subdirectory in the tree.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because `-b` removes all ACL entries; it is not a prerequisite for `-m` and would work against the goal here.
    *   *Option C* is incorrect because named-user entries apply to regular files exactly as well as directories.
    *   *Option D* is incorrect because the mask caps *effective* permission of entries that exist — it doesn't explain files having no entry applied to them at all.
</details>

---

### Question 2
After granting `auditor-tom` a named ACL entry of `r-x` on `/srv/projects/orion`, you set the directory's mask with `sudo setfacl -m m::r-- /srv/projects/orion`. What is auditor-tom's actual effective access now?
*   **A)** Still `r-x`, because the mask only affects the traditional group-owner entry, never named entries.
*   **B)** `r--` — the mask caps every named user/group entry's effective permission, so the `x` bit is now blocked regardless of what the named entry itself grants.
*   **C)** `rwx`, because named entries always override a more restrictive mask.
*   **D)** No access at all, because setting the mask manually revokes every named entry on the file.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** The mask entry caps the effective permission of every named user entry, named group entry, and the owning-group entry. A named entry of `r-x` against a mask of `r--` means the effective permission is the intersection of the two — `r--` only. The named entry itself is unchanged in `getfacl` output, but its *effective* grant is reduced.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because the mask specifically targets named entries (and the owning group); only the file-owner entry and "other" entry are exempt from it.
    *   *Option C* is incorrect — named entries never override a more restrictive mask; the mask is a hard cap, not a suggestion.
    *   *Option D* is incorrect because setting the mask does not delete or disable any entries; it only limits their effective permission.
</details>

---

### Question 3
A shared directory needs contractor access today, and needs every file created in it a month from now to automatically carry the same access, with no manual `setfacl` re-run required for new files. Which single addition accomplishes the second half of that requirement?
*   **A)** Running `setfacl -R -m u:contractor-jane:rwx` again periodically via a cron job.
*   **B)** Setting a default ACL entry with `setfacl -d -m u:contractor-jane:rwx` on the parent directory.
*   **C)** Adding `contractor-jane` to the directory's owning group.
*   **D)** Changing the directory's mode to `777` so any new file inherits full access automatically.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A default ACL entry (`-d`) is a template the kernel consults at file-creation time. Any new file or subdirectory created under a directory carrying a default ACL automatically receives that entry as its own access ACL, with zero manual intervention needed at creation time.
*   **Why others are incorrect:**
    *   *Option A* is a fragile workaround that only catches new files periodically and requires ongoing maintenance, not automatic inheritance.
    *   *Option C* violates the explicit requirement of not changing group membership, and grants broader access than intended.
    *   *Option D* is a serious security regression — it grants full read-write-execute to literally everyone, not scoped access to one contractor.
</details>

---

### Question 4
User `mallory` has a line in her `.bashrc` reading `ulimit -Sp 100`, intended to cap her process count. A cron job running as `mallory` still manages to fork far past 100 processes and destabilizes the server. Why did the `.bashrc` restriction fail to apply?
*   **A)** `ulimit -Sp` only limits open file descriptors, not process count.
*   **B)** `.bashrc` is only sourced for interactive, non-login shells; cron jobs don't source it at all, so the limit never applies to that code path.
*   **C)** The limit was set as a hard limit, and hard limits don't apply to background jobs.
*   **D)** `ulimit` values only take effect after a full system reboot.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `.bashrc` is sourced specifically for interactive, non-login shells. Cron jobs, non-interactive SSH commands, and many systemd-launched sessions never source `.bashrc` at all, so any `ulimit` command placed there simply never executes for those paths — leaving exactly the automated, script-driven processes most likely to misbehave completely unrestricted.
*   **Why others are incorrect:**
    *   *Option A* is incorrect because `-p` (or `-u` on some shells) specifically targets `nproc`, the max process count, not file descriptors.
    *   *Option C* is incorrect — the line as written set a *soft* limit (`-S`), and regardless, the actual failure is that `.bashrc` was never sourced by the cron path at all.
    *   *Option D* is incorrect — `ulimit` is a per-session shell setting; it has nothing to do with reboot cycles.
</details>

---

### Question 5
You write a perfectly-formed entry, `jackie hard nproc 150`, into `/etc/security/limits.d/jackie-nproc.conf`. After a fresh SSH login, `ulimit -Hp` for jackie still reports `unlimited`. What is the most likely cause, and where should you check first?
*   **A)** The file must be named exactly `limits.conf`; drop-in files under `limits.d` are never read.
*   **B)** `pam_limits.so` is missing (or commented out) from the `session` stack of the PAM service governing this login path — check `/etc/pam.d/sshd` and any included `common-session`/`system-auth` file.
*   **C)** `nproc` limits only apply to root-owned processes.
*   **D)** The value must be set as `soft`, not `hard`, for SSH sessions specifically.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `limits.conf`/`limits.d` entries are only ever applied by `pam_limits.so`, and only for PAM service stacks that actually include that module in their `session` block. If it's absent or commented out for the login path being used (commonly `sshd`, `login`, or a shared `common-session`/`system-auth` file), every limits entry on the system is parsed by nothing and has zero effect — this is the single most common reason a correctly-written limits file appears to silently do nothing.
*   **Why others are incorrect:**
    *   *Option A* is incorrect — `/etc/security/limits.d/*.conf` drop-ins are read identically to entries in the main `limits.conf` file; this is the recommended pattern, not a broken one.
    *   *Option C* is incorrect — `nproc` limits apply to the named non-root user exactly as configured.
    *   *Option D* is incorrect — `hard` is the correct type for an unraisable ceiling; switching to `soft` would make it user-adjustable, the opposite of what's needed.
</details>
