#!/usr/bin/env bash

set -euo pipefail

# skip if already installed
command -v syncthing > /dev/null 2>&1 && echo "syncthing already installed, skipping" && exit 0

# register official apt repo 
if [[ ! -f /etc/apt/sources.list.d/syncthing.list ]]; then
     sudo mkdir -p /etc/apt/keyrings
     sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
     echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2" | sudo tee /etc/apt/sources.list.d/syncthing.list
fi
# install syncthing
sudo apt update && sudo apt install syncthing -y

# start background daemons
systemctl --user enable syncthing
systemctl --user start syncthing
