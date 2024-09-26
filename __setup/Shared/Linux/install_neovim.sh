#!/usr/bin/env bash
NVIM_CMD=nvim
WGET_CMD=wget

if command -v -- "$WGET_CMD" > /dev/null 2>&1; then
    if ! command -v -- "$NVIM_CMD" > /dev/null 2>&1; then
        wget https://github.com/neovim/neovim/release/latest/download/nvim.appimage
	chmod +x ./nvim.appimage
	sudo mv nvim.appimage /usr/local/bin/nvim
    fi
else
   echo "Installing $NVIM_CMD depends on $WGET_CMD. Please install $WGET_CMD"
fi
