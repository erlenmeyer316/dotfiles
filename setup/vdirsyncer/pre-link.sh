#!/usr/bin/env bash

set -euo pipefail

if [ ! -d "$HOME/.local/share/vdirsyncer/status" ]; then
   mkdir -p "$HOME/.local/share/vdirsyncer/status"
fi
