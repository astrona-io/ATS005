#!/usr/bin/env bash
set -euo pipefail
sudo groupadd -g 5000 datateam
sudo usermod -aG datateam marta
sudo usermod -aG datateam cilla
sudo groupmod -n platform-ops legacy-ops
sudo groupdel temp-audit
