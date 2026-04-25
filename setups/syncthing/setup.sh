#!/usr/bin/env bash

set -euo pipefail

NAS_DEVICE_ID="7QPLJJ2-3ZBQKPB-5OWUBZI-YF3MHST-QIRPSEC-PMNA426-FB64FU2-BOLNTQQ"
NAS_DEVICE_NAME="DickiNas"
SYNC_DIR="$HOME/Sync"
CONFIG_XML="${XDG_STATE_HOME:-$HOME/.local/state}/syncthing/config.xml"

# Start daemon 

if systemctl --user is-active --quiet syncthing; then
    echo "[syncthing] daemon already running."
else
    echo "[syncthing] enabling and starting daemon..."
    systemctl --user enable syncthing
    systemctl --user start syncthing
fi

# Get the syncthing API key
CFG=$(echo "$CONFIG_XML")
API_KEY=$(grep -oP '(?<=apikey>)[^<]+' "$CFG")

# Wait for the API to become ready before sending CLI commands
echo "[syncthing] waiting for API to be ready..."
until curl -s -H "X-API-KEY: $API_KEY"  http://127.0.0.1:8384/rest/system/ping &> /dev/null; do
    sleep 1
done
echo "[syncthing] API is up."

#  Configure preferences 

# Name this device by its hostname
syncthing cli config devices add --name "$(hostname)"

# Opt out of anonymous usage reporting
syncthing cli config options uraccepted set 0

# Create and register the default sync base directory
mkdir -p "$SYNC_DIR"
syncthing cli config defaults folder path set "$SYNC_DIR"

# Register DickiNas 

# Check if DickiNas is already in config before adding
if syncthing cli config devices list | grep -q "$NAS_DEVICE_ID"; then
    echo "[syncthing] $NAS_DEVICE_NAME already registered, skipping."
else
    echo "[syncthing] adding $NAS_DEVICE_NAME..."
    syncthing cli config devices add \
        --device-id "$NAS_DEVICE_ID" \
        --name "$NAS_DEVICE_NAME"
    syncthing cli config devices "$NAS_DEVICE_ID" auto-accept-folders set true
    echo "[syncthing] $NAS_DEVICE_NAME added. Go accept this device on the NAS side."
fi

# Restart to apply config changes

echo "[syncthing] restarting to apply config..."
systemctl --user restart syncthing

echo "[syncthing] done. Run 'st-pending' after accepting on the NAS to see offered folders."
