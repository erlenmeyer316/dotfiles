#!/usr/bin/env bash

set -euo pipefail

# skip if already installed
command -v st > /dev/null 2>&1 && exit 0

ST_BUILD_DIR="/tmp/dotfiles/build/st"
ST_GIT_REPO="https://github.com/erlenmeyer316/st"

mkdir -p "$ST_BUILD_DIR"
git -C "$ST_BUILD_DIR" clone "$ST_GIT_REPO" .
make -C "$ST_BUILD_DIR"
sudo make -C "$ST_BUILD_DIR" install
rm -rf "$ST_BUILD_DIR"
