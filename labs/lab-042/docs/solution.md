# Solution Walkthrough

This guide explains how to populate an LDAP directory structure by creating Organizational Units (OUs), POSIX groups, and POSIX-compliant user accounts using LDIF templates, and how to verify user authentication over an encrypted StartTLS channel.

---

## Step 1: Write and apply the Organizational Unit structure

An LDAP directory is structured as a tree. Before adding any users or groups, we must create their respective container nodes (called **Organizational Units**, or **OUs**).

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
Let's break down this command:
*   `ldapadd`: The utility used to create new entries in the directory.
*   `-x`: Enforces simple authentication.
*   `-D "cn=admin,dc=example,dc=com"`: Specifies the admin account we are authenticating as.
*   `-w "LdapRoot!2024"`: Supplies the admin password we defined during server setup.
*   `-H ldap://127.0.0.1`: Connects to the local server.

---

## Step 2: Write and apply POSIX groups and user records

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
*   **Why order matters:** This command will fail if you run it before Step 1. LDAP is a strict hierarchical database and cannot create child nodes (like `uid=lfcsuser,ou=people,...`) if their parent node (`ou=people,...`) does not exist yet.

---

## Step 3: Configure the user's password

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

## Step 4: Verify the directory population

Let's query our directory to confirm that all records have been populated successfully.

```bash
ldapsearch -x -ZZ -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 \
  -b "dc=example,dc=com" "(uid=lfcsuser)"
```
Let's break down this query command:
*   `-ZZ`: **Enforces StartTLS**. This ensures our connection is secure and encrypted.
*   `-b "dc=example,dc=com"`: Defines the **search base**. The client will search this node and any child nodes underneath it.
*   `"(uid=lfcsuser)"`: The **search filter**. Tells the server to only return entries where the `uid` matches `lfcsuser`.

Verify the group is also searchable:
```bash
ldapsearch -x -ZZ -D "cn=admin,dc=example,dc=com" -w "LdapRoot!2024" -H ldap://127.0.0.1 \
  -b "dc=example,dc=com" "(cn=developers)"
```

---

## Step 5: Test authenticating as the new user over StartTLS

We want to prove that the new user can successfully log in and authenticate over an encrypted network connection.

```bash
ldapwhoami -x -D "uid=lfcsuser,ou=people,dc=example,dc=com" -w "LfcsLdap!2024" -ZZ -H ldap://127.0.0.1
```
*   **Expected Output:** `dn:uid=lfcsuser,ou=people,dc=example,dc=com`. This confirms that:
    1.  The user's DN is valid and searchable.
    2.  The password we set in Step 3 is correct.
    3.  The authentication was successfully negotiated over a secure TLS channel.

Once all verification steps pass, run the local validation suite to pass the lab!
