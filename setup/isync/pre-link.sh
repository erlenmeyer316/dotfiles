#!/usr/bin/env bash

set -euo pipefail

if [ ! -d "$HOME/.local/mail/adam.dickison@posteo.net" ]; then
   mkdir -p "$HOME/.local/mail/adam.dickison@posteo.net"
fi


if [ ! -d "$HOME/.local/mail/adam.dickison@gmail.com" ]; then
   mkdir -p "$HOME/.local/mail/adam.dickison@gmail.com"
fi
