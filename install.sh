#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

# run the stow command for the package in app config ($2) in the target directory ($1)
stow_package() {
	tgt=$1
	app=$2
	# -v verbose
	# -R recursive
	# -t target
    	cd $SCRIPT_DIR
	stow -v -R -t ${tgt} ${app}
}

# base packages  
base=(
	bin
	btop
	kitty
	lazygit
	neofetch
	qutebrowser
	ranger
	shell
	stow
	tmux
	w3m
)

user_only=(
	git
	isync
	kard
	msmtp
	neomutt
	ssh
	vdirsyncer
)

# macos specific packages
darwin_only=(
        homebrew
	skhd
	sketchybar
	yabai
)

# arch linux specific packages
archlinux_only=(
	pacman
	wttr
	i3
)

# ubuntu specific packages
ubuntu_only=(
	apt
)


# gather os and version information
if [ -f /etc/os-release ]; then
	# freedesktop.org and systemd
	. /etc/os-release
	OS=$NAME
	VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
	# linuxbase.org
	OS=$(lsb_release -si)
	VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
	# for some versions of Debian/Ubuntu without lsb_release command
	. /etc/lsb-release
	OS=$DISTRIB_ID
	VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
	# Old Debian/Ubuntu/etc.
	OS=Debian
	VER=$(cat /etc/debian_version)
else
	# Fallback to uname
	OS=$(uname -s)
	VER=$(uname -r)
fi

# gather system architecture
ARCH=$(uname -m)

# determine setup path based on os information
SETUP_SCRIPT_FOLDER=$(echo "./__setup/${OS// /}")


# pull and update any submodules
git submodule init
git submodule update


if [ "$OS" == "Arch Linux" ]; then
    # install arch only configuration
    for app in ${archlinux_only[@]}; do
       stow_package "${HOME}" "$app"
    done

    # run setup script
    cd $SETUP_SCRIPT_FOLDER
    ./setup_${ARCH}.sh
fi

if [ "$OS" == "Ubuntu" ]; then
    # install ubuntu only configuration
    for app in ${ubuntu_only[@]}; do
       stow_package "${HOME}" "$app"   
    done

    # run setup script
    cd $SETUP_SCRIPT_FOLDER/$VER
    ./setup_${ARCH}.sh
fi

if [ "$OS" == "Darwin" ]; then
   # create folder structure
   [[ ! -d $HOME/.config ]] && mkdir $HOME/.config

   # configure stow
   if [ ! -f $HOME/.stow-global-ignore ]; then
       echo "\.DS_Store" > $HOME/.stow-global-ignore
   else
       if [ -z $(grep "\.DS_Store" "$HOME/.stow-global-ignore") ]; then 
           echo "\.DS_Store" > $HOME/.stow-global-ignore; 
       fi
   fi

   # install Mac only configuration
   for app in ${darwin_only[@]}; do
       stow_package "${HOME}" "$app"
   done

   # run setup script
   cd $SETUP_SCRIPT_FOLDER
   ./setup_${ARCH}.sh
fi


# install base config
for app in ${base[@]}; do
	stow_package "${HOME}" $app
done


# install local user config
for app in ${user_only[@]}; do
	if [[ "$(whoami)" != *"root"* ]]; then
	    stow_package "${HOME}" $app
	fi
done

[[ -f $SETUP_SCRIPT_FOLDER/post_${ARCH}.sh ]] && cd $SETUP_SCRIPT_FOLDER && ./post_${ARCH}.sh

echo "#### Done!"
