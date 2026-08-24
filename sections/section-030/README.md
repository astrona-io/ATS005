# Section 030: Shell Environment, Profiles & PATH

Every account on a Linux system lives inside a small forest of configuration files that decide what its shell actually looks like: which variables are set, which editor opens by default, and which directories are searched when you type a bare command name. None of this happens by magic. Every one of these files is read by a specific mechanism, at a specific moment, for a specific *kind* of session — and the exam (and real production incidents) will absolutely test whether you know which file fires when.

Get this wrong and the failure mode is never "sometimes broken." A variable set in the wrong dotfile is *precisely and predictably* absent from every session type that never sources that file — perfectly present in your interactive SSH session, mysteriously gone inside a cron job or a systemd unit. A `PATH` entry placed in the wrong position is worse: it can silently let a user-writable directory shadow a real system command, turning a convenience feature into a privilege-escalation vector.

---

## What You Will Master

By completing this section, you will acquire two tightly-coupled administrative capabilities:
*   **Environment Profile Placement:** Knowing precisely which file — `/etc/environment`, `/etc/profile.d/*.sh`, `~/.bash_profile`, or `~/.bashrc` — is the correct home for a given variable, based on whether it must reach login shells, non-login interactive shells, one user, or the whole system.
*   **Safe PATH Extension:** Understanding that `PATH` is searched left to right, first match wins, and that where you place a new directory in that list is a security decision — appending is safe, prepending onto a user-writable directory is a shadowing risk.

---

## The Learning & Lab Path

This section is divided into two focused modules, each paired with a dedicated hands-on virtual sandbox practice lab, and concluded with a comprehensive Capstone Integration Challenge:

### 1. System-Wide & Personal Environment Profiles
*   **Module Reader:** **[Module 1: System-Wide & Personal Environment Profiles](./module-01/course.md)**
*   **Practice Lab Sandbox:** **`labs/lab-031`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-031
    ```
*   **Hands-on Objective:** Set a proxy variable system-wide so it reaches both login and non-login interactive shells via the correct PAM-parsed drop-in, and set a personal editor preference for exactly one user without touching any other account.

### 2. Extending PATH Safely
*   **Module Reader:** **[Module 2: Extending PATH Safely](./module-02/course.md)**
*   **Practice Lab Sandbox:** **`labs/lab-032`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-032
    ```
*   **Hands-on Objective:** Persistently append a personal scripts directory to one user's `PATH` in the correct login-shell dotfile, then prove a same-named decoy script placed there does not shadow the real system command.

### 3. Section Capstone Challenge
*   **Comprehensive Challenge:** **`labs/lab-030` (Shell Environment & PATH Capstone)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-030
    ```
*   **Hands-on Objective:** Connect the dots. Configure a system-wide variable through the proper drop-in, set a personal variable for one user only, and safely extend that same user's `PATH` without shadowing any existing system command — then prove all three with `env` and `type` evidence.

---

## Ready for Assessment?

Test your theoretical knowledge and diagnostic reasoning before tackling the practical lab missions:

*   **[Take the Section 030 Knowledge Check Quiz](./quiz.md)**
