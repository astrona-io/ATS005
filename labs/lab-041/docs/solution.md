# Solution Walkthrough

This guide explains how to configure a secure OpenLDAP server, define organizational base domains and administrator credentials via LDIF files, configure secure TLS channels (StartTLS and LDAPS), and verify secure connectivity.

---

## Step 1: Inspect the baseline environment

Before making any changes, let's explore the current directory services status and certificate layout:

```bash
sudo systemctl status slapd
sudo ss -tlnp | grep -E ':389|:636'
ls -l /etc/ldap/certs/
```
*   `systemctl status slapd`: OpenLDAP runs as the `slapd` (Stand-Alone LDAP Daemon) system service.
*   `ss -tlnp`: Confirms port `389` (default unencrypted LDAP) is currently listening, but secure port `636` (LDAPS) is not yet active.
*   `ls -l /etc/ldap/certs/`: Confirms that the pre-generated certificate and key files exist and are owned by the `openldap` system user account.

---

## Step 2: Generate a password hash for the administrator

For security, we must never store passwords in plaintext inside server configurations. We will use the `slappasswd` tool to generate a strong password hash.

```bash
slappasswd
# New password: LdapRoot!2024
# Re-enter new password: LdapRoot!2024
```
Copy the generated hash printed on the screen (e.g. `{SSHA}xxxxxxxxxxxxx`). You will use this exact hash in the next step.

---

## Step 3: Configure base domain and administrator credentials

Modern OpenLDAP uses a dynamic configuration database named `cn=config` (also called "on-the-fly configuration" or "OLC"). Instead of editing static configuration files, we modify OLC by writing LDAP Data Interchange Format (LDIF) files and applying them to the running daemon.

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

---

## Step 4: Configure TLS certificates on the server

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

---

## Step 5: Enable secure LDAPS network listener port

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

---

## Step 6: Verify secure LDAP operations

Let's run a series of verification checks to confirm the server is fully secured.

### 1. Verify network ports are listening
```bash
sudo ss -tlnp | grep -E ':389|:636'
```
Confirm both `389` and `636` show `LISTEN` status under the control of `slapd`.

### 2. Verify secure SSL/TLS connection on port 636
```bash
openssl s_client -connect 127.0.0.1:636 -brief </dev/null
```
*   `s_client`: Tests secure TCP connections.
*   **What to look for:** You should see a successful SSL handshake. A message like `Verify return code: 18 (self-signed certificate)` is expected and correct because we are using our self-signed certificate.

### 3. Verify StartTLS connection upgrade on port 389
```bash
ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base
```
*   `-x`: Uses simple authentication.
*   `-ZZ`: **Enforces StartTLS**. This tells the client to immediately upgrade the unencrypted port 389 connection to secure TLS encryption. If the server does not support TLS, the command will fail immediately. This ensures your password is never sent in the clear!
*   **Expected Output:** Displays the base Directory System Agent (DSA) metadata.

### 4. Verify Administrator Authentication
Verify that we can successfully bind as the administrator over an encrypted connection using our password:
```bash
ldapwhoami -x -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -ZZ -H ldap://127.0.0.1
```
*   `-D "dn"`: Sets the Distinguished Name we want to log in (bind) as.
*   `-w "password"`: Supplies our password.
*   **Expected Output:** `dn:cn=admin,dc=example,dc=com`. This confirms that we successfully authenticated as the admin over a fully secure, TLS-encrypted StartTLS channel.

Once all of the above tests pass, run the local validation suite to pass the lab!
