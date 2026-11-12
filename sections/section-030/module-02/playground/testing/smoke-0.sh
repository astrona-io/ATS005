#!/usr/bin/env bash
set -euo pipefail
for tool in bash su; do command -v "$tool"; done
