#!/usr/bin/env bash
set -euo pipefail
sudo setfacl -d -m u:qa-nina:rx /srv/data/atlas
