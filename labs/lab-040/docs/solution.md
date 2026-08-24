# Solution Walkthrough

This guide explains how to configure a secure OpenLDAP server, define organizational base domains and administrator credentials via LDIF files, populate the directory, configure secure SSSD client authentication, and verify NSS resolution order.

---

## Part 1: Server & TLS

Modern OpenLDAP uses a dynamic configuration database named `cn=config` (also called "on-the-fly configuration" or "OLC"). Instead of editing static configuration files, we modify OLC by writing LDAP Data Interchange Format (LDIF) files and applying them to the running daemon.

### Step 1: Generate a password hash for the administrator
For security, we must never store passwords in plaintext inside server configurations. We will use the `slappasswd` tool to generate a strong password hash.
```bash
slappasswd
# New password: LdapRoot!2024
# Re-enter new password: LdapRoot!2024
```
Copy the generated hash printed on the screen (e.g. `{SSHA}xxxxxxxxxxxxx`). You will use this exact hash in the next step.

### Step 2: Configure base domain and administrator credentials
First, identify the exact database index that controls the storage engine:
```bash
sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcMdbConfig)" dn
```
*   `-Y EXTERNAL`: Specifies standard system user authentication (SASL EXTERNAL), letting us authenticate using our root-level OS credentials.
*   `-H ldapi:///`: Connects to slapd using a local, unencrypted UNIX socket instead of a network port.
*   **Result:** Usually, this returns `dn: olcDatabase={1}mdb,cn=config`.

Create an LDIF file to update the base suffix, admin DN, and password hash:
```bash
cat > /tmp/set-suffix.ldif << 'EOF'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
-
replace: olcRootDN
olcRootDN: cn=admin,dc=example,dc=com
-
replace: olcRootPW
olcRootPW: {SSHA}your_copied_hash_here
EOF
```
*   `replace: olcSuffix`: Sets the root suffix to `dc=example,dc=com` (mapping our organization's domain name into LDAP's hierarchical tree structure).
*   `replace: olcRootDN`: Defines the administrator's distinguished name (DN).
*   `replace: olcRootPW`: Overwrites the administrator password with our secure hash.
*   `-`: The hyphen character is used to separate multiple modification operations within a single LDIF entry.

Apply the LDIF configuration changes:
```bash
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set-suffix.ldif
```
*   `ldapmodify`: Applies changes in-place to the running database configuration dynamically.

### Step 3: Configure TLS certificates on the server
We need to tell `cn=config` where the server certificates live so it can encrypt incoming connections.

Create an LDIF file to configure the TLS file paths:
```bash
cat > /tmp/set-tls.ldif << 'EOF'
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/certs/ldap-server.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/certs/ldap-server.key
-
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ldap/certs/ldap-server.crt
EOF
```
*   `olcTLSCertificateFile`: Defines the public server certificate.
*   `olcTLSCertificateKeyFile`: Defines the private key file.
*   `olcTLSCACertificateFile`: Defines the Certificate Authority (CA) cert. Since we are using a self-signed certificate in this lab, the server's certificate is its own trust anchor, so we point both variables to the same file.

Apply the TLS configuration changes:
```bash
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set-tls.ldif
```

### Step 4: Enable secure LDAPS network listener port
OpenLDAP's network port listeners are configured in `/etc/default/slapd`. We want to enable both standard port `389` (supporting unencrypted and StartTLS connections) and secure port `636` (native LDAPS).

Open the configuration file:
```bash
sudo vi /etc/default/slapd
```
Find the line starting with `SLAPD_SERVICES` and change it to:
```text
SLAPD_SERVICES="ldap:/// ldaps:/// ldapi:///"
```
Let's break down these listener schemes:
*   `ldap:///`: Listens on port `389` (unencrypted, upgradeable to StartTLS).
*   `ldaps:///`: Listens on port `636` (SSL/TLS encrypted from the initial packet).
*   `ldapi:///`: Listens on the local UNIX socket (allowing system admins to manage the database via SASL EXTERNAL).

Restart the service to bind the new network ports:
```bash
sudo systemctl restart slapd
```

### Step 5: Verify secure LDAP operations
Let's run a series of verification checks to confirm the server is fully secured.

Verify network ports are listening:
```bash
sudo ss -tlnp | grep -E ':389|:636'
```
Confirm both `389` and `636` show `LISTEN` status under the control of `slapd`.

Verify secure SSL/TLS connection on port 636:
```bash
openssl s_client -connect 127.0.0.1:636 -brief </dev/null
```
*   `s_client`: Tests secure TCP connections.
*   **What to look for:** You should see a successful SSL handshake. A message like `Verify return code: 18 (self-signed certificate)` is expected and correct because we are using our self-signed certificate.

Verify StartTLS connection upgrade on port 389:
```bash
ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base
```
*   `-x`: Uses simple authentication.
*   `-ZZ`: **Enforces StartTLS**. This tells the client to immediately upgrade the unencrypted port 389 connection to secure TLS encryption. If the server does not support TLS, the command will fail immediately. This ensures your password is never sent in the clear!
*   **Expected Output:** Displays the base Directory System Agent (DSA) metadata.

Verify Administrator Authentication:
Verify that we can successfully bind as the administrator over an encrypted connection using our password:
```bash
ldapwhoami -x -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -ZZ -H ldap://127.0.0.1
```
*   `-D "dn"`: Sets the Distinguished Name we want to log in (bind) as.
*   `-w "password"`: Supplies our password.
*   **Expected Output:** `dn:cn=admin,dc=example,dc=com`. This confirms that we successfully authenticated as the admin over a fully secure, TLS-encrypted StartTLS channel.

---

## Part 2: Directory Population

An LDAP directory is structured as a tree. Before adding any users or groups, we must create their respective container nodes (called **Organizational Units**, or **OUs**).

### Step 6: Write and apply the Organizational Unit structure
Create an LDIF file defining OUs for people and groups:
```bash
cat > /tmp/ou-structure.ldif << 'EOF'
dn: ou=people,dc=example,dc=com
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=example,dc=com
objectClass: organizationalUnit
ou: groups
EOF
```
Let's analyze this LDIF syntax:
*   `dn:`: The **Distinguished Name** uniquely identifies this node's exact position in the directory tree.
*   `objectClass: organizationalUnit`: Specifies that this entry represents a standard organizational folder structure.
*   `ou: name`: The friendly name of the organizational unit.

Apply this structure to the directory as the administrator:
```bash
ldapadd -x -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 -f /tmp/ou-structure.ldif
```

### Step 7: Write and apply POSIX groups and user records
Now that our container OUs exist, we can add our group and user records inside them.

Create an LDIF file defining the POSIX group and user:
```bash
cat > /tmp/lfcsuser.ldif << 'EOF'
dn: cn=developers,ou=groups,dc=example,dc=com
objectClass: posixGroup
cn: developers
gidNumber: 5000

dn: uid=lfcsuser,ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: LFCS User
sn: User
uid: lfcsuser
uidNumber: 10001
gidNumber: 5000
homeDirectory: /home/lfcsuser
loginShell: /bin/bash
EOF
```
Let's analyze these schemas and attributes:
*   `objectClass: posixGroup`: Defines this entry as an OS-level Linux group. It requires a `gidNumber` (set to `5000` here).
*   `objectClass: inetOrgPerson`: A standard internet contact record schema containing first/last name fields (`cn` and `sn`).
*   `objectClass: posixAccount`: **Critical.** This extension tells the system that this LDAP record represents a real Linux operating system user. It makes UNIX attributes mandatory, including:
    *   `uidNumber`: A unique user ID (set to `10001` here).
    *   `gidNumber`: Matches the user's primary group GID (`5000`, mapping to `developers`).
    *   `homeDirectory`: The user's home folder path (`/home/lfcsuser`).
    *   `loginShell`: The user's default shell (`/bin/bash`).
*   `objectClass: shadowAccount`: Enables shadow password aging policies (such as expiration and locking support).

Apply this group and user template to the directory:
```bash
ldapadd -x -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 -f /tmp/lfcsuser.ldif
```
*   **Why order matters:** This command will fail if you run it before creating the OUs. LDAP is a strict hierarchical database and cannot create child nodes (like `uid=lfcsuser,ou=people,...`) if their parent node (`ou=people,...`) does not exist yet.

### Step 8: Configure the user's password
With the user account created, we will set a secure password for the user. While we can store passwords inside our initial LDIF using the `userPassword` attribute, it is highly recommended to set it dynamically using the `ldappasswd` command.

```bash
ldappasswd -x -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 \
  -s "LfcsLdap!2024" \
  "uid=lfcsuser,ou=people,dc=example,dc=com"
```
*   `ldappasswd`: Sets or updates an LDAP user password.
*   `-s "LfcsLdap!2024"`: Supplies the new password. (If you omit `-s`, the tool will securely prompt you to type the password interactively).
*   The trailing string is the exact target user Distinguished Name (DN) whose password we are changing.

---

## Part 3: SSSD Client Integration

SSSD (System Security Services Daemon) is the modern, standard Linux service that connects local system authentication libraries to remote identity providers (like LDAP or Active Directory).

### Step 9: Write the SSSD configuration file
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

### Step 10: Lock down SSSD file permissions and wire nsswitch.conf
SSSD handles sensitive information, including cached user security databases. For safety, SSSD enforces strict permission checks at startup. If the configuration file is too open, the daemon will refuse to start.

Configure the correct owner and permissions:
```bash
sudo chown root:root /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf
```
*   `chown root:root`: Restricts file ownership to the system administrator (`root`).
*   `chmod 600`: Sets permissions to read and write for the owner only, and absolutely no access for any other group or user.

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

### Step 11: Start SSSD and verify in order
With configuration and permissions set up, start SSSD and configure it to run automatically at system boot time:
```bash
sudo systemctl enable --now sssd
```
*   `enable --now`: Enables the service to start automatically at boot, and starts it immediately in the current session.

Verify that the daemon started successfully:
```bash
sudo systemctl status sssd
```

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

Once all parts pass, run the local validation suite to pass the lab!
