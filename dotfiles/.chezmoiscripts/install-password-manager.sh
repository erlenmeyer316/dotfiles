#! /bin/sh

# exit immediately if keepassxc-cli is already in $PATH
type keepassxc-cli > /dev/null 2>&1 && echo "keepassxc is already installed" && exit

case "$(uname -s)" in
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
	echo "$(uname s) is an unsupported OS"
	exit 1
        ;;
esac
