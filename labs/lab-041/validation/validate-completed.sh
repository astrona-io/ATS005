#!/usr/bin/env bash
# Confirms slapd serves dc=example,dc=com, listens on 389 and 636, negotiates
# TLS on both, and accepts the admin bind with the expected rootPW.

set -u

ADMIN_DN="cn=admin,dc=example,dc=com"
ADMIN_PASSWORD="LdapRoot!2024"

if ! systemctl is-active --quiet slapd; then
  echo "FAIL: slapd is not active"
  exit 1
fi

if ! ss -tln 2>/dev/null | grep -q ':389 '; then
  echo "FAIL: nothing is listening on port 389"
  exit 1
fi

if ! ss -tln 2>/dev/null | grep -q ':636 '; then
  echo "FAIL: nothing is listening on port 636 - is ldaps:/// in SLAPD_SERVICES?"
  exit 1
fi

suffix=$(sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=config" "(olcSuffix=*)" olcSuffix 2>/dev/null | grep -i '^olcSuffix:' | awk '{print $2}')
if [[ "$suffix" != "dc=example,dc=com" ]]; then
  echo "FAIL: expected olcSuffix 'dc=example,dc=com', got '${suffix:-<empty>}'"
  exit 1
fi

rootdn=$(sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=config" "(olcRootDN=*)" olcRootDN 2>/dev/null | grep -i '^olcRootDN:' | cut -d' ' -f2-)
if [[ "$rootdn" != "$ADMIN_DN" ]]; then
  echo "FAIL: expected olcRootDN '$ADMIN_DN', got '${rootdn:-<empty>}'"
  exit 1
fi

if ! openssl s_client -connect 127.0.0.1:636 </dev/null >/tmp/lab041-tls-check.log 2>&1; then
  echo "FAIL: TLS handshake against 127.0.0.1:636 did not complete"
  cat /tmp/lab041-tls-check.log
  exit 1
fi

if ! grep -qi "CN=localhost\|BEGIN CERTIFICATE" /tmp/lab041-tls-check.log; then
  echo "FAIL: openssl s_client did not present a server certificate on 636"
  exit 1
fi

if ! ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base >/dev/null 2>/tmp/lab041-starttls-check.log; then
  echo "FAIL: ldapsearch -ZZ against ldap://127.0.0.1 (StartTLS required) did not succeed"
  cat /tmp/lab041-starttls-check.log
  exit 1
fi

if ! ldapwhoami -x -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -ZZ -H ldap://127.0.0.1 >/tmp/lab041-whoami-check.log 2>&1; then
  echo "FAIL: admin bind as $ADMIN_DN with the expected rootPW over StartTLS did not succeed"
  cat /tmp/lab041-whoami-check.log
  exit 1
fi

rm -f /tmp/lab041-tls-check.log /tmp/lab041-starttls-check.log /tmp/lab041-whoami-check.log

echo "PASS: slapd serves dc=example,dc=com, listens on 389/636, TLS negotiates, and the admin bind works."
exit 0
