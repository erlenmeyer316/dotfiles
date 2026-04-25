#!/usr/bin/env bash

set -euo pipefail

if command -v syncthing &> /dev/null; then
    echo "[syncthing] already installed, skipping."
else
    echo "[syncthing] installing from official apt repo..."
    if [[ ! -f /etc/apt/sources.list.d/syncthing.list ]]; then
        sudo mkdir -p /etc/apt/keyrings
        sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg \
            https://syncthing.net/release-key.gpg
        echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] \
https://apt.syncthing.net/ syncthing stable" \
            | sudo tee /etc/apt/sources.list.d/syncthing.list
    fi
    sudo apt update && sudo apt install syncthing -y
fi
