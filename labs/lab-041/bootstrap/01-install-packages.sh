#!/usr/bin/env bash
# Installs OpenLDAP server/client packages and pre-generates a self-signed
# TLS cert/key pair for lab-041. Base DN, admin credentials, and the actual
# cn=config TLS/listener wiring are left as the student's task.
set -eu

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y slapd ldap-utils openssl

mkdir -p /etc/ldap/certs

if [[ ! -f /etc/ldap/certs/ldap-server.key ]]; then
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout /etc/ldap/certs/ldap-server.key \
    -out /etc/ldap/certs/ldap-server.crt \
    -days 3650 \
    -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
fi

chown openldap:openldap /etc/ldap/certs/ldap-server.key /etc/ldap/certs/ldap-server.crt
chmod 640 /etc/ldap/certs/ldap-server.key
chmod 644 /etc/ldap/certs/ldap-server.crt

echo "Bootstrap complete: slapd installed, TLS cert/key pre-generated at /etc/ldap/certs/."
exit 0
