#!/usr/bin/env bash
STARSHIP_CMD=starship

if ! command -v -- "$STARSHIP_CMD" > /dev/null 2>&1; then
   curl -sS https://starship.rs/install.sh | sh 
fi
