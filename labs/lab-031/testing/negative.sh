#!/usr/bin/env bash
set -euo pipefail
sudo sed -i s/EDITOR=vim/EDITOR=wrong/ /home/candidate/.bash_profile
