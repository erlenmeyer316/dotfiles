#!/usr/bin/env bash

set -euo pipefail

if [ ! -d "$HOME/.cache/vdirsyncer/status" ]; then
   mkdir -p "$HOME/.cache/vdirsyncer/status"
fi

if [ ! -d "$HOME/.local/contacts/adam.dickison@posteo.net" ]; then
   mkdir -p "$HOME/.local/contacts/adam.dickison@posteo.net"
fi

if [ ! -d "$HOME/.local/mail/posteo/INBOX" ]; then
   mkdir -p "$HOME/.local/mail/posteo/INBOX"
fi
