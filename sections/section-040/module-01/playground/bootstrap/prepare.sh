#!/usr/bin/env bash
# OS prep for PLAYGROUND — LDAP Server Installation & TLS
# Runs once when the environment comes up. Installs the OpenLDAP server and
# client tools and pre-generates a self-signed TLS certificate + key (owned by
# the openldap service account), so the reader can focus on wiring cn=config.
# The directory is left with only the package defaults. Nothing to solve.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[playground] ldap-server-tls: installing slapd + ldap-utils..."
apt-get update -qq
apt-get install -y -qq slapd ldap-utils openssl >/dev/null

# --- pre-generate a self-signed cert/key the daemon can read --------------
install -d -m 755 /etc/ldap/certs
if [ ! -f /etc/ldap/certs/ldap-server.crt ]; then
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout /etc/ldap/certs/ldap-server.key \
        -out    /etc/ldap/certs/ldap-server.crt \
        -days 3650 \
        -subj "/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" 2>/dev/null
fi
chown openldap:openldap /etc/ldap/certs/ldap-server.key /etc/ldap/certs/ldap-server.crt
chmod 640 /etc/ldap/certs/ldap-server.key
chmod 644 /etc/ldap/certs/ldap-server.crt

systemctl enable --now slapd >/dev/null 2>&1 || true

echo "[playground] ready. slapd is up on :389 with default config; cert/key at /etc/ldap/certs/."
echo "  Try:  sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config -LLL dn"
