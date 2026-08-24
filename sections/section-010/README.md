# Section 010: Local Account & Group Lifecycle

Welcome to your first major domain in Linux identity administration. In this section, we move past treating a user account as a single `useradd` command and start managing the entire lifecycle of local identity: who owns what group, where a home directory actually lives, how privilege is scoped, and how an account ages, locks, and eventually retires.

As an administrator, you are responsible for the full lifecycle of every local account and group on a system — from the moment a new hire's account is provisioned, through group reorganizations and security investigations, to the day an offboarded contractor's account is removed for good. Get any single flag wrong along the way — `-G` instead of `-aG`, a home directory move with no `-m`, a sudoers rule that's a hair off from the exact invoked command — and the mistake either silently fails or silently over-grants access.

---

## What You Will Master

By completing this section, you will acquire three core administrative capabilities:
*   **Account Provisioning & Scoped Privilege:** How to correctly reassign an existing account's primary group and home directory, provision a brand-new account with the right supplementary groups from the start, and grant exact-command `sudo` privilege without opening a security hole.
*   **Group Lifecycle Management:** How to create a group with a pinned GID, safely rename and delete groups, and understand exactly when a membership change takes effect in an already-open session.
*   **Account Lifecycle & Aging:** How to confirm what `useradd`'s defaults actually are before assuming them, force a password reset without ever knowing the old password, distinguish password aging from account expiration, lock and unlock an account without deleting it, and remove an account cleanly.

---

## The Learning & Lab Path

This section is divided into three highly focused, sequential modules. Each module is paired with a dedicated hands-on virtual sandbox practice lab, and concluded with a comprehensive Capstone Integration Challenge:

### 1. User & Group Account Management
*   **Module Reader:** **[Module 1: User & Group Account Management](./module-01/course.md)**
*   **Practice Lab Sandbox:** **`labs/lab-011`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-011
    ```
*   **Hands-on Objective:** Reassign an existing user's primary group and home directory (moving its contents), provision a brand-new account with the right supplementary groups, and grant one exact-command `NOPASSWD` sudo rule via a `/etc/sudoers.d/` drop-in.

### 2. Group Lifecycle Management
*   **Module Reader:** **[Module 2: Group Lifecycle Management](./module-02/course.md)**
*   **Practice Lab Sandbox:** **`labs/lab-012`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-012
    ```
*   **Hands-on Objective:** Create a group with a pinned GID, add existing users as supplementary members without disturbing their other groups, rename a legacy group without losing its GID or membership, and delete a genuinely unused group.

### 3. Account Lifecycle: Defaults, Aging & Locking
*   **Module Reader:** **[Module 3: Account Lifecycle: Defaults, Aging & Locking](./module-03/course.md)**
*   **Practice Lab Sandbox:** **`labs/lab-013`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-013
    ```
*   **Hands-on Objective:** Provision an account using the system's actual confirmed defaults, force a password reset on next login, set a hard account-expiration date, lock an account under investigation, and remove a fully offboarded account along with its home directory.

### 4. Section Capstone Challenge
*   **Comprehensive Challenge:** **`labs/lab-010` (Local Account & Group Lifecycle Capstone)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-010
    ```
*   **Hands-on Objective:** Connect the dots. Relocate an account's primary group and home directory, provision a new account with a scoped sudo rule, create and rename groups without losing membership, lock one account, force-expire another, and cleanly remove an offboarded one.

---

## Ready for Assessment?

Test your theoretical knowledge and diagnostic reasoning before tackling the practical lab missions:

*   **[Take the Section 010 Knowledge Check Quiz](./quiz.md)**
