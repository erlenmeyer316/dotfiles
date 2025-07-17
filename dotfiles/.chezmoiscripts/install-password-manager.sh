#! /bin/sh


if [ -f /etc/os-release ]; then
    source /etc/os-release
else
    if [ -x "$(command -v uname)" ]; then
        ID=$(uname -s)
	VERSION_ID=$(uname -r)
    fi
fi

# exit immediately if keepassxc-cli is already in $PATH
type keepassxc-cli > /dev/null 2>&1 && echo "keepassxc is already installed" 

case $ID in
    arch)
	sudo pacman -Sy keepassxc
	;;
    debian)
    ubuntu)
	sudo apt install keepassxc
        ;;
    Darwin)
	brew install keepassxc
        ;;
    *)
	echo "$(uname -s) is an unsupported OS"
	exit 1
        ;;
esac
