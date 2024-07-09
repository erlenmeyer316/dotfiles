#!/usr/bin/env bash

APT_SOURCES_DIR="$HOME/.config/apt/Ubuntu/22.04/sources.list.d"
APT_SOURCES_DEST_DIR="/etc/apt/sources.list.d"

# Loop through each file in the source directory
if [ -d "$APT_SOURCES_DIR" ] && [ -d "$APT_SOURCES_DEST_DIR" ]; then
   for file in "$APT_SOURCES_DIR"/*; do
       # Check if the current item is a regular file
       if [ -f "$file" ]; then
           filename=$(basename "$file")
           # Create a symlink in the destination directory
           sudo ln -sf "$file" "$APT_SOURCES_DEST_DIR/$filename"
           echo "Symlink created for $filename"
       fi
   done
fi

echo "!==========================================================!"
echo "!======!! TODO: AUTOMATE GPG KEYS FOR CUSTOM REPOS !!======!"
echo "!==========================================================!"

APT_CONF_DIR="$HOME/.config/apt/Ubuntu/22.04/apt.conf.d"
APT_CONF_DEST_DIR="/etc/apt/apt.conf.d"

# Loop through each file in the source directory
if [ -d "$APT_CONF_DIR" ] && [ -d "$APT_CONF_DEST_DIR" ]; then
   for file in "$APT_CONF_DIR"/*; do
       # Check if the current item is a regular file
       if [ -f "$file" ]; then
           filename=$(basename "$file")
           # Create a symlink in the destination directory
           sudo ln -sf "$file" "$APT_CONF_DEST_DIR/$filename"
           echo "Symlink created for $filename"
       fi
   done
fi

# Refresh apt sources
sudo apt update

# Install packages from list
echo "Installing packages..."
OFFICIAL_PACKAGES=$HOME/.config/apt/Ubuntu/22.04/packages.list
if [ -f "$OFFICIAL_PACKAGES" ]; then	
   xargs sudo apt-get -y install < $OFFICIAL_PACKAGES
fi

PARENT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
GRANDPARENT_DIR=$( cd -- "$( dirname -- "$PARENT_DIR}" )" &> /dev/null && pwd)
SHARED_DIR="$( cd -- "$( dirname -- "$GRANDPARENT_DIR" )" &> /dev/null && pwd)/Shared/Linux"

#Install lazygit
source "$SHARED_DIR/install_lazygit.sh"
source "$SHARED_DIR/install_starship.sh"
source "$SHARED_DIR/install_go.sh"
source "$SHARED_DIR/install_fzf.sh"
