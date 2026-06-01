#!/usr/bin/env bash

set -euo pipefail

if [ ! -d "$HOME/.local/share/calendars/adam.dickison@posteo.net" ]; then
   mkdir -p "$HOME/.local/share/calendars/adam.dickison@posteo.net"
fi

if [ ! -d "$HOME/.local/share/calendars/holidays" ]; then
   mkdir -p "$HOME/.local/share/calendars/holidays"
fi
