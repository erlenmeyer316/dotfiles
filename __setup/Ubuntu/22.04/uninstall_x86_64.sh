#!/usr/bin/env bash


APT_SOURCES_DIR="$HOME/.config/apt/Ubuntu/22.04/sources.list.d"
APT_SOURCES_DEST_DIR="/etc/apt/sources.list.d"

# Loop through each symlink in the destination directory
if [ -d "$APT_SOURCES_DIR" && -d "$APT_SOURCES_DEST_DIR" ]; then
   for symlink in "$APT_SOURCES_DEST_DIR"/*; do
       # Check if the current item is a symlink
       if [ -L "$symlink" ]; then
           # Resolve the symlink path to the actual file
           target=$(readlink -f "$symlink")
        
           # Check if the symlink points to a file in the source directory
           if [[ "$target" == "$APT_SOURCES_DIR"* ]]; then
               filename=$(basename "$symlink")
               # Remove the symlink
               rm -f "$symlink"
               echo "Symlink removed for $filename"
           fi
       fi
   done
fi


APT_CONF_DIR="$HOME/.config/apt/Ubuntu/22.04/apt.conf.d"
APT_CONF_DEST_DIR="/etc/apt/apt.conf.d"

# Loop through each symlink in the destination directory
if [ -d "$APT_CONF_DIR" && -d "$APT_CONF_DEST_DIR" ]; then
   for symlink in "$APT_CONF_DEST_DIR"/*; do
       # Check if the current item is a symlink
       if [ -L "$symlink" ]; then
           # Resolve the symlink path to the actual file
           target=$(readlink -f "$symlink")
        
           # Check if the symlink points to a file in the source directory
           if [[ "$target" == "$APT_CONF_DIR"* ]]; then
               filename=$(basename "$symlink")
               # Remove the symlink
               rm -f "$symlink"
               echo "Symlink removed for $filename"
           fi
       fi
   done
fi


# Dump installed packages list
echo "A list of installed packages has been written to ~/ubuntu.pkglist."
OFFICIAL_PACKAGES=$HOME/.config/apt/packages.list
if [ -f "$OFFICIAL_PACKAGE" ]; then
   cp $OFFICIAL_PACKAGES ~/
fi

