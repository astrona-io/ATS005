#!/usr/bin/env bash
# Prepares marta/cilla, legacy-ops, and temp-audit for lab-012
set -eu

sudo groupadd -f staff

for u in marta cilla; do
  if ! id "$u" >/dev/null 2>&1; then
    sudo useradd -m -g staff "$u"
  fi
done

if ! getent group legacy-ops >/dev/null; then
  sudo groupadd -g 4200 legacy-ops
fi
if ! id opadmin >/dev/null 2>&1; then
  sudo useradd -m -g staff -G legacy-ops opadmin
else
  sudo usermod -aG legacy-ops opadmin
fi

sudo groupadd -f temp-audit

echo "Ready for group lifecycle management lab."
exit 0
