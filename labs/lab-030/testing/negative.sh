#!/usr/bin/env bash
set -euo pipefail
sudo sed -i s/EDITOR=nano/EDITOR=wrong/ /home/candidate/.bash_profile
