#!/usr/bin/env bash
set -euo pipefail
for tool in ldapsearch; do command -v "$tool"; done
ldapsearch -x -ZZ -H ldap://127.0.0.1 -b "" -s base namingContexts >/dev/null
