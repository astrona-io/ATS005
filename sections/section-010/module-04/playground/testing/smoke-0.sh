#!/usr/bin/env bash
set -euo pipefail
for tool in useradd getent; do command -v "$tool"; done
