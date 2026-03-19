#!/usr/bin/env bash

set -euo pipefail

FONT_BUILD_DIR="/tmp/dotfiles/downloads/fonts"
FONT_DIR="$HOME/.fonts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

while IFS= read -r font_name; do
        if [[ ${font_name:0:1} == "#" ]]; then
	   continue
	fi
	if fc-list --format="%{family}"\n | grep -qi "${font_name}"; then
           echo "Font ${font_name} already installed..."
	else
           curl -OL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_name.zip"
           mkdir -p  "${FONT_DIR}"
           echo "unzip the $font_name.zip"
           unzip "$font_name.zip" -d "$FONT_DIR/$font_name/"
	   rm "$font_name.zip" 
           fc-cache -fv
           echo "Installed font $font_name"     
	fi
done < "${SCRIPT_DIR}/nerd.fontlist"
