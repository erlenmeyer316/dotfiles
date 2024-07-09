#!/usr/bin/env bash

# Restore original pacman.conf
PAC_BAK=$HOME/.config/pacman/pacman.conf.orig
if [ -f "$PAC_BAK" ]; then
   echo "Restoring /etc/pacman.conf..."
   sudo mv -f $PAC_BAK /etc/pacman.conf
fi

# Dump installed official packages list
echo "A list of installed official packages has been written to ~/pacman.pkglist."
OFFICIAL_PACKAGES=$HOME/.config/pacman/package_lists/pacman.pkglist 
cp $OFFICIAL_PACKAGS ~/

# Dump installed AUR packages list
echo "A list of installed AUR packages has been written to ~/yay.pkglist."
AUR_PACKAGES=$HOME/.config/pacman/package_lists/yay.pkglist 
cp $AUR_PACKAGES ~/

