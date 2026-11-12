#!/usr/bin/env bash
set -euo pipefail
sudo setfacl -d -m u:auditor-tom:rx /srv/projects/orion
