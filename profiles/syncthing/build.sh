#!/usr/bin/env bash

set -euo pipefail

# install syncthing from the official apt repo if not installed 
if [[ command -v syncthing > /dev/null 2>&1 ]]; then
    echo "Syncthing already installed."
else
    # register official apt repo 
    if [[ ! -f /etc/apt/sources.list.d/syncthing.list ]]; then
        sudo mkdir -p /etc/apt/keyrings
        sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg \
		https://syncthing.net/release-key.gpg
        echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2" \ 
		| sudo tee /etc/apt/sources.list.d/syncthing.list
    fi
    
    # install syncthing
    sudo apt update && sudo apt install syncthing -y
fi

# set device name
syncthing cli config device local name set "$(hostname)"

# disable usage reporting
syncthing cli config options uracepted set -1

# set default folder base path 
mkdir -p $HOME/syncthing
syncthing cli config defaults folder path set $HOME/syncthing

# disable the browser auto-open on start
syncthing cli config gui autoUpgradeIntervalH set 0

# start background daemons if not started
if [[ systemctl is-active --quiet syncthing ]]; then
    echo "Syncthing daemon is already started."
else
    # start background daemons
    systemctl --user enable syncthing
    systemctl --user start syncthing
fi

# register remote if not registered

