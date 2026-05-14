#!/usr/bin/env bash

set -euo pipefail

# skip if already installed
if [ -f "$HOME/.config/nvm/nvm.sh" ]; then
	echo "[nvm] is already installed. Skipping."
	exit 0
fi

if ! command -v curl &> /dev/null; then
    print_msg "[nvm] requires curl"
    exit 0
fi

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
