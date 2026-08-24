# Section 040: Centralized Identity with LDAP

Every account you have created so far in this course has lived in exactly one place: the local `/etc/passwd` and `/etc/shadow` files of a single machine. That model breaks down the moment an organization has more than a handful of servers. Nobody wants to create the same account, with the same UID, the same group memberships, and the same password, by hand, twenty separate times — and nobody wants to *remove* an ex-employee's access from twenty separate places either. The industry-standard answer is a centralized directory: one authoritative source of identity that every server in the fleet consults.

This section builds that directory from absolute zero and connects a client to it, in the correct dependency order. You will install and secure an OpenLDAP server, populate it with real POSIX users and groups, and then configure `sssd` on a client to treat that directory as a source of truth for both identity resolution and authentication — all while keeping every bind, search, and password exchange off the wire in plaintext.

---

## What You Will Master

By completing this section, you will acquire three tightly-coupled administrative capabilities:
*   **Directory Server Provisioning:** Installing OpenLDAP, understanding the `cn=config` dynamic configuration backend, setting a base DN and admin credentials, and wiring a TLS certificate and key into the server so both StartTLS (389) and native LDAPS (636) are available.
*   **Directory Population & Bind Verification:** Writing valid LDIF to create organizational units, POSIX groups, and POSIX users; setting passwords the right way; and proving — not assuming — that an authenticated bind only succeeds over an encrypted connection.
*   **Client-Side Identity Integration:** Configuring `sssd` as the modern NSS/PAM broker between a Linux host and an LDAP backend, wiring `nsswitch.conf` correctly, and verifying resolution before ever touching login, all without breaking local accounts like `root`.

---

## The Learning & Lab Path

This section is divided into three focused modules, each paired with a dedicated hands-on virtual sandbox practice lab, and concluded with a comprehensive Capstone Integration Challenge. Every lab in this section runs on a single QEMU VM — the "directory server" and the "directory client" are the same machine, reached over `127.0.0.1`/`localhost`, so you can observe both sides of every bind and search in one place.

### 1. LDAP Server Installation & TLS
*   **Module Reader:** **[Module 1: LDAP Server Installation & TLS](./module-01/course.md)**
*   **Practice Lab Sandbox:** **`labs/lab-041`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-041
    ```
*   **Hands-on Objective:** Install OpenLDAP, set the base DN and admin credentials via `cn=config`, wire a pre-supplied TLS certificate and key into the server, and confirm it listens on both 389 (StartTLS) and 636 (native LDAPS) with a working handshake.

### 2. LDAP Directory Population & TLS Bind Verification
*   **Module Reader:** **[Module 2: LDAP Directory Population & TLS Bind Verification](./module-02/course.md)**
*   **Practice Lab Sandbox:** **`labs/lab-042`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-042
    ```
*   **Hands-on Objective:** Populate a running, TLS-capable, empty directory with `ou=people`/`ou=groups`, a POSIX group, and a full POSIX user via LDIF, set that user's password, and prove an authenticated bind succeeds over TLS.

### 3. LDAP Client Integration with SSSD
*   **Module Reader:** **[Module 3: LDAP Client Integration with SSSD](./module-03/course.md)**
*   **Practice Lab Sandbox:** **`labs/lab-043`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-043
    ```
*   **Hands-on Objective:** Configure `sssd.conf` and `nsswitch.conf` to resolve and authenticate an LDAP-provided user against the directory server built in Modules 1-2, verifying NSS resolution before login while confirming local accounts remain unaffected.

### 4. Section Capstone Challenge
*   **Comprehensive Challenge:** **`labs/lab-040` (Centralized Identity with LDAP Capstone)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS005.git -c labs/lab-040
    ```
*   **Hands-on Objective:** Connect the dots. Stand up and secure an OpenLDAP server with TLS, populate it with organizational structure and a real POSIX user, and wire `sssd` on the very same host to resolve and authenticate that user — while proving local accounts never stop working.

---

## Ready for Assessment?

Test your theoretical knowledge and diagnostic reasoning before tackling the practical lab missions:

*   **[Take the Section 040 Knowledge Check Quiz](./quiz.md)**
