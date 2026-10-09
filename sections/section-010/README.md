# Section 010: Local Account & Group Lifecycle

Welcome to your first section on Linux identity, astronaut. Here you stop treating a user account as a single `useradd` command. You manage the whole life of every local account and group on the ship: which team a crew member belongs to, where their quarters (home directory) really are, how much of the captain's authority they get through `sudo`, and how their account ages, locks and finally leaves the crew roster.

Small mistakes in this work rarely make a noise. Use `-G` instead of `-aG`, move a home directory without `-m`, or write a `sudo` rule that is one word away from the real command, and the change either fails quietly or grants far too much. This section teaches you to get each step right and to prove it.

---

## What You Will Master

When you finish this section, you can do three things well:

* **Account provisioning and scoped privilege:** move an existing account to a new primary group and home directory, create a new account with the right supplementary groups from the start, and grant one exact command through `sudo` without opening a security hole.
* **Group lifecycle management:** create a group with a fixed GID, rename and delete groups safely, and know exactly when a membership change reaches a session that is already open.
* **Account lifecycle and aging:** check what the `useradd` defaults really are before you rely on them, force a password change without knowing the old password, tell password aging from account expiration, lock and unlock an account without deleting it, and remove an account cleanly.

---

## The Learning & Lab Path

This section has three modules, taken in order. Each module ends with a graded lab on its own training ship, and the section closes with a capstone lab that combines all three.

### 1. User & Group Account Management

* **Module reader:** **[User & Group Account Management](./module-01/course.md)**
* **Practice lab:** **`labs/lab-011`**
* **Lab run command:**
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-011
    ```
* **Hands-on goal:** move an existing user to a new primary group and home directory with its files, create a new account with the right supplementary groups, and grant one exact `NOPASSWD` command through a drop-in file in `/etc/sudoers.d/`.

### 2. Group Lifecycle Management

* **Module reader:** **[Group Lifecycle Management](./module-02/course.md)**
* **Practice lab:** **`labs/lab-012`**
* **Lab run command:**
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-012
    ```
* **Hands-on goal:** create a group with a fixed GID, add existing users to it without disturbing their other groups, rename an old group without losing its GID or members, and delete a group that nothing uses.

### 3. Account Lifecycle: Defaults, Aging & Locking

* **Module reader:** **[Account Lifecycle: Defaults, Aging & Locking](./module-03/course.md)**
* **Practice lab:** **`labs/lab-013`**
* **Lab run command:**
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-013
    ```
* **Hands-on goal:** create an account with the system's real defaults, force a password change at the next login, set a hard account expiration date, lock an account under investigation, and remove an offboarded account with its home directory.

### 4. Section Capstone Challenge

* **Capstone lab:** **`labs/lab-010` (Local Account & Group Lifecycle Capstone)**
* **Lab run command:**
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS005.git -c labs/lab-010
    ```
* **Hands-on goal:** put it all together. Move one account to a new group and home, create a new account with a scoped `sudo` rule, create and rename groups without losing members, lock one account, set another to expire, and remove a third cleanly.

---

## Ready for Assessment?

Test your knowledge and your reasoning before you take on the practical missions:

* **[Take the Section 010 Knowledge Check Quiz](./quiz.md)**
