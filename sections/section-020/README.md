# Section 020: Access Control & Resource Limits

Astronaut, the standard owner, group and other permissions take you a long way. But a real ship soon needs more precision than three buckets can give, and more control over what one crew member may use than a startup file can enforce. This section covers both gaps.

As an administrator, you grant exactly the access a task needs, no more and no less. You also make sure a resource limit holds however a session started. The Linux Foundation Certified System Administrator (LFCS) exam tests both skills directly, and both have a "looks right but quietly is not" failure that this section trains you to avoid.

---

## What You Will Learn

By the end of this section, you will have two core skills:

*   **Access control lists (ACLs):** give extra users read-write or read-only access to a shared directory tree without adding them to a group, and make that access carry over to every new file in the tree with default ACLs.
*   **Resource limits enforced by PAM:** replace a fragile `ulimit` line in one user's `.bashrc` with a real hard limit in `/etc/security/limits.d/`, read by `pam_limits.so` (PAM is Pluggable Authentication Modules, the checklist every login passes through), and cap concurrent logins for a whole group with `maxlogins`.

---

## The Learning & Lab Path

This section has two focused modules. Each one ends with a hands-on lab on its own virtual machine, and the section closes with a capstone lab that combines them:

### 1. POSIX Access Control Lists
*   **Module:** **[POSIX Access Control Lists](./module-01/course.md)**
*   **Practice lab:** **`labs/lab-021`**
*   **Lab run command:**
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-021
    ```
*   **Hands-on goal:** give one outside contractor read-write access and one auditor read-only access to a shared project directory with ACLs only, without touching group membership, and set default ACLs so every new file gets the same entries.

### 2. PAM Resource Limits & Concurrent Logins
*   **Module:** **[PAM Resource Limits & Concurrent Logins](./module-02/course.md)**
*   **Practice lab:** **`labs/lab-022`**
*   **Lab run command:**
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-022
    ```
*   **Hands-on goal:** find the process limit a coworker set in a `.bashrc` line, set that number as a hard `nproc` limit through PAM, and cap a whole group to one login at a time with `maxlogins`.

### 3. Section Capstone Challenge
*   **Capstone:** **`labs/lab-020` (Access Control & Resource Limits)**
*   **Lab run command:**
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-020
    ```
*   **Hands-on goal:** put it all together on one machine. Give two outside users inherited ACL access to a shared directory, replace a per-user `.bashrc` limit with a hard PAM limit, and cap a group to one login each.

---

## Ready for Assessment?

Test your knowledge and your troubleshooting before you start the graded missions:

*   **[Take the Section 020 Knowledge Check Quiz](./quiz.md)**
