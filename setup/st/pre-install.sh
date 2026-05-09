#!/usr/bin/env bash

set -euo pipefail

# skip if already installed
command -v st > /dev/null 2>&1 && echo "[st] installed" && exit 0

if ! command -v git &> /dev/null; then
    print_msg "[st] requires curl"
    exit 0
fi

if ! command -v make >/dev/null 2>&1; then
    print_msg "[st] requires unzip"
    exit 0
fi

ST_BUILD_DIR="/tmp/dotfiles/build/st"
ST_GIT_REPO="https://github.com/erlenmeyer316/st"

mkdir -p "$ST_BUILD_DIR"
git -C "$ST_BUILD_DIR" clone "$ST_GIT_REPO" .
make -C "$ST_BUILD_DIR"
sudo make -C "$ST_BUILD_DIR" install
rm -rf "$ST_BUILD_DIR"
