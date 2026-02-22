if [ $(command -v "nala") ]; then
    
    # Alias apt to nala
    apt() {
        command nala "$@"
    }

    # Alias sudo to handle nala command
    sudo() {
        if [ "$1" = "apt" ]; then
	   shift
	   command sudo nala "$@"
	else
	   command sudo "$@"
	fi
    }
fi
