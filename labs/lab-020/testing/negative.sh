#!/usr/bin/env bash
set -euo pipefail
sudo setfacl -x d:u:qa-nina /srv/data/atlas
