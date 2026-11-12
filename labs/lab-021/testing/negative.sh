#!/usr/bin/env bash
set -euo pipefail
sudo setfacl -x d:u:auditor-tom /srv/projects/orion
