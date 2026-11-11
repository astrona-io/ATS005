#!/usr/bin/env bash
set -euo pipefail
sudo sed -i s/EDITOR=wrong/EDITOR=vim/ /home/candidate/.bash_profile
