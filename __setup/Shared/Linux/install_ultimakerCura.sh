##!/usr/bin/env bash
CURA_CMD=cura
WGET_CMD=wget
CURA_VER=5.8.0
CURA_REL=Ultimaker-Cura-${CURA_VER}-linux-X64.AppImage

if command -v -- "$WGET_CMD" > /dev/null 2>&1; then
    if ! command -v -- "$CURA_CMD" > /dev/null 2>&1; then
	wget https://github.com/Ultimaker/Cura/releases/download/${CURA_VER}/${CURA_REL}
	chmod +x ./${CURA_REL}
	sudo mv ./${CURA_REL} /usr/local/bin/cura
    fi
else
   echo "Installing $CURA_CMD depends on $WGET_CMD. Please install $WGET_CMD"
fi
