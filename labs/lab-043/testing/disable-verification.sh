#!/usr/bin/env bash
set -eu
sudo sed -i "s/ldap_tls_reqcert = demand/ldap_tls_reqcert = never/" /etc/sssd/sssd.conf
sudo systemctl restart sssd
