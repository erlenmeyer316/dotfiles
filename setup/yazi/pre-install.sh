#!/usr/bin/env bash

set -euo pipefail

# skip if already installed
command -v yazi > /dev/null 2>&1 && echo "[yazi] is already installed. Skipping." && exit 0

if ! command -v git &> /dev/null; then
    print_msg "[yazi] requires curl"
    exit 0
fi

if [ ! -f "/etc/apt/trusted.gpg.d/debian.griffo.io.gpg" ]; then
    curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg
fi

if [ ! -f "/etc/apt/sources.list.d/debian.griffo.io.list" ]; then
    echo "deb https://debian.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/debian.griffo.io.list
fi
