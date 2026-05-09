#!/usr/bin/env bash

set -euo pipefail

if ! dir_exists "$HOME/.local/bin"; then
   mkdir -p "$HOME/.local/bin"
fi


