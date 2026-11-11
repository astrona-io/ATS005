#!/usr/bin/env bash
set -eu
sudo mkdir -p /etc/sssd
sudo tee /etc/sssd/sssd.conf >/dev/null <<'EOF'
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
ldap_tls_reqcert = demand
ldap_tls_cacert = /etc/ldap/certs/ldap-server.crt
cache_credentials = True
EOF
sudo chown root:root /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf
sudo sed -i -E 's/^passwd:.*/passwd: files sss/; s/^group:.*/group: files sss/' /etc/nsswitch.conf
sudo systemctl enable sssd
sudo systemctl restart sssd
for attempt in $(seq 1 20); do
  getent -s sss passwd lfcsuser && exit 0
  sleep 2
done
exit 1
