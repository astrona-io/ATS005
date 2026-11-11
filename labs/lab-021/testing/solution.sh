#!/usr/bin/env bash
set -euo pipefail
sudo setfacl -R -m u:contractor-jane:rwx,u:auditor-tom:rx /srv/projects/orion
sudo setfacl -d -m u:contractor-jane:rwx,u:auditor-tom:rx /srv/projects/orion
