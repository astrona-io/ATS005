#!/usr/bin/env bash
set -eu
sudo openssl req -x509 -nodes -newkey rsa:2048 -keyout /tmp/untrusted-test.key -out /etc/ldap/certs/unrelated.crt -days 1 -subj /CN=unrelated
sudo sed -i 's|ldap_tls_cacert = .*|ldap_tls_cacert = /etc/ldap/certs/unrelated.crt|' /etc/sssd/sssd.conf
sudo systemctl restart sssd
