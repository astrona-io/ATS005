# Solution Walkthrough

This guide explains how to configure SSSD (System Security Services Daemon) on a Linux host to authenticate users against a secure OpenLDAP server, integrate LDAP users into the standard Name Service Switch (NSS) resolution path, and verify resolution order.

---

## Step 1: Write the SSSD configuration file

SSSD (System Security Services Daemon) is the modern, standard Linux service that connects local system authentication libraries to remote identity providers (like LDAP or Active Directory).

Create or edit the main SSSD configuration file:
```bash
sudo vi /etc/sssd/sssd.conf
```
Add the following configuration text exactly:
```ini
[sssd]
config_file_version = 2
services = nss, pam
domains = example.com

[domain/example.com]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://127.0.0.1
ldap_search_base = dc=example,dc=com
ldap_id_use_start_tls = true
ldap_tls_cacert = /etc/ldap/certs/ldap-server.crt
cache_credentials = True
```
Let's analyze what these parameters do:
*   `services = nss, pam`: Tells SSSD to provide user lookup databases (NSS) and session authentication support (PAM).
*   `id_provider = ldap`: Specifies that user and group identifiers will be queried from an LDAP directory.
*   `ldap_uri = ldap://127.0.0.1`: The network address of the directory server.
*   `ldap_search_base`: The starting node in the LDAP directory where SSSD will search for users and groups.
*   `ldap_id_use_start_tls = true`: **Enforces StartTLS encryption** for all queries. SSSD will refuse to send information in unencrypted plaintext.
*   `ldap_tls_cacert`: Points to the server's public certificate so SSSD can verify and trust the connection. Since the server uses a self-signed certificate, the certificate acts as its own Certificate Authority (CA) trust anchor.
*   `cache_credentials = True`: Allows SSSD to cache user credentials locally. This is useful in production because if the LDAP server experiences a temporary outage, users who have logged in before can still log in using their cached details.

---

## Step 2: Lock down SSSD file permissions

SSSD handles sensitive information, including cached user security databases. For safety, SSSD enforces strict permission checks at startup. If the configuration file is too open, the daemon will refuse to start.

Configure the correct owner and permissions:
```bash
sudo chown root:root /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf
```
*   `chown root:root`: Restricts file ownership to the system administrator (`root`).
*   `chmod 600`: Sets permissions to read and write for the owner only, and absolutely no access for any other group or user.

---

## Step 3: Add SSSD to the Name Service Switch (NSS)

Linux programs do not query SSSD or LDAP directly. Instead, they ask standard library functions like `getpwnam()` to look up users. These functions look inside `/etc/nsswitch.conf` to determine which database databases to search and in what order.

Open the switch configuration file:
```bash
sudo vi /etc/nsswitch.conf
```
Find the lines for `passwd` and `group`, and append `sss` to the end:
```text
passwd:         files sss
group:          files sss
```
*   **Why order is critical:** The system searches databases from left to right.
    *   `files`: Looks inside local files first (`/etc/passwd` and `/etc/group`).
    *   `sss`: If the user or group is not found locally, query SSSD (which queries LDAP).
    *   This ordering ensures that critical system accounts (like `root`) resolve instantly from local disk, keeping the system stable and bootable even if SSSD is stopped or the network goes down!

---

## Step 4: Start and enable the SSSD daemon

With configuration and permissions set up, start SSSD and configure it to run automatically at system boot time:

```bash
sudo systemctl enable --now sssd
```
*   `enable --now`: Enables the service to start automatically at boot, and starts it immediately in the current session.

Verify that the daemon started successfully:
```bash
sudo systemctl status sssd
```
If the service failed to start, inspect the system logs to identify the error (usually due to incorrect permissions in Step 2 or syntax errors in Step 1):
```bash
sudo journalctl -u sssd -n 50 --no-pager
```

---

## Step 5: Verify user and group resolution

Let's test the entire resolution chain in the exact sequence requested by security policies:

### 1. Verify remote LDAP user resolution
```bash
getent passwd lfcsuser
```
*   `getent`: Queries our administrative databases.
*   **Expected Output:** A standard passwd line for `lfcsuser` showing UID `10001`, GID `5000`, home directory `/home/lfcsuser`, and login shell `/bin/bash`. This confirms that NSS successfully queried SSSD, which successfully queried LDAP!

### 2. Verify remote LDAP group resolution
```bash
getent group developers
```
*   **Expected Output:** `developers:x:5000:`. Confirms the group resolves with GID `5000`.

### 3. Verify user identification
```bash
id lfcsuser
```
*   **Expected Output:** Confirms that UID `10001` belongs to `lfcsuser`, and their primary group GID is `5000` (`developers`).

### 4. Confirm local accounts are unaffected
We must ensure that our remote lookup configurations did not disrupt local system accounts.
```bash
getent passwd root
id root
```
*   **Expected Output:** Completely normal local output (UID `0`, group `0`). This proves that local accounts resolve instantly from local disk, completely unaffected by SSSD.

Once all of the above tests pass, run the local validation suite to pass the lab!
