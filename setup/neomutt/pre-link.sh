#!/usr/bin/env bash

set -euo pipefail

if [ ! -d "$HOME/.cache/vdirsyncer/status" ]; then
   mkdir -p "$HOME/.cache/vdirsyncer/status"
fi

if [ ! -d "$HOME/.local/contacts/" ]; then
   mkdir -p "$HOME/.local/contacts/"
fi

if [ ! -d "$HOME/.local/mail/" ]; then
   mkdir -p "$HOME/.local/mail/"
fi
