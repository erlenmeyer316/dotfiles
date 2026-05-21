#!/usr/bin/env bash

set -euo pipefail


if [ ! -d "$HOME/.cache/neomutt/headers" ]; then
   mkdir -p "$HOME/.cache/neomutt/headers"
fi

if [ ! -d "$HOME/.cache/neomutt/bodies" ]; then
   mkdir -p "$HOME/.cache/neomutt/bodies"
fi

if [ ! -d "$HOME/.cache/neomutt/certificates" ]; then
   mkdir -p "$HOME/.cache/neomutt/certificates"
fi


