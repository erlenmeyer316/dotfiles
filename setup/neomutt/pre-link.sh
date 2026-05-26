#!/usr/bin/env bash

set -euo pipefail


if [ ! -d "$HOME/.cache/neomutt/headers" ]; then
   mkdir -p "$HOME/.cache/neomutt/headers"
fi

if [ ! -d "$HOME/.cache/neomutt/messages" ]; then
   mkdir -p "$HOME/.cache/neomutt/messages"
fi

if [ ! -d "$HOME/.cache/neomutt/certificates" ]; then
   mkdir -p "$HOME/.cache/neomutt/certificates"
fi


