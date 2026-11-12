#!/usr/bin/env bash
set -euo pipefail
for tool in getfacl setfacl; do command -v "$tool"; done
