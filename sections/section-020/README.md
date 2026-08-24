# Section 020: Access Control & Resource Limits

Standard Unix ownership and permission bits get you remarkably far, but real infrastructure quickly needs more precision than three buckets (owner, group, other) can express — and more discipline around what a single account is allowed to consume than a shell dotfile can enforce. This section covers both halves of that gap.

As an administrator, you are responsible for granting exactly the access a task requires — no more, no less — and for making sure a resource restriction actually holds regardless of how a session was started. Both skills are tested directly on the LFCS exam, and both have a "looks right but silently isn't" failure mode that this section is built to drill out of you.

---

## What You Will Master

By completing this section, you will acquire two core administrative capabilities:
*   **Access Control Lists:** How to grant specific extra users read-write or read-only access to a shared directory tree — without adding them to a group — and how to make sure that access automatically extends to every file created in that tree from now on, using default ACLs.
*   **PAM-Enforced Resource Limits:** How to replace a fragile per-user `.bashrc` `ulimit` hack with a real, globally-enforced hard limit via `/etc/security/limits.conf` and `pam_limits.so`, and how to cap concurrent logins for an entire group with `maxlogins`.

---

## The Learning & Lab Path

This section is divided into two focused modules, each paired with a dedicated hands-on virtual sandbox practice lab, and concluded with a comprehensive Capstone Integration Challenge:

### 1. POSIX Access Control Lists
*   **Module Reader:** **[Module 1: POSIX Access Control Lists](./module-01/course.md)**
*   **Practice Lab Sandbox:** **`labs/lab-021`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-021
    ```
*   **Hands-on Objective:** Grant one external contractor read-write access and one auditor read-only access to a shared project directory entirely via ACLs, without touching group membership, and configure default ACLs so every future file automatically inherits the same rules.

### 2. PAM Resource Limits & Concurrent Logins
*   **Module Reader:** **[Module 2: PAM Resource Limits & Concurrent Logins](./module-02/course.md)**
*   **Practice Lab Sandbox:** **`labs/lab-022`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-022
    ```
*   **Hands-on Objective:** Discover a user's live effective soft process limit, replace a `.bashrc` hack with a proper PAM-enforced hard `nproc` limit using that exact number, and cap an entire group to one concurrent login with `maxlogins`.

### 3. Section Capstone Challenge
*   **Comprehensive Challenge:** **`labs/lab-020` (Access Control & Resource Limits)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-020
    ```
*   **Hands-on Objective:** Connect the dots. Grant scoped, inheriting ACL access to two different external users on a shared directory, then replace a sloppy per-user resource-limit hack with a proper PAM hard limit and enforce a group-wide `maxlogins` cap — all on the same box.

---

## Ready for Assessment?

Test your theoretical knowledge and diagnostic reasoning before tackling the practical lab missions:

*   **[Take the Section 020 Knowledge Check Quiz](./quiz.md)**
