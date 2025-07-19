#
# ~/.bashrc.d/functions.sh
#

# Create a directory and move into it
mkcd() {
    mkdir -p -- "$1" && cd -- "$1"
}

# Extract compressed files
extract() {
    if [ -f "$1" ]; then
        case "$1" in
	    *.tar.bz2)	tar xvjf "$1"				;;
	    *.tar.gz)	tar xvzf "$1"				;;
	    *.bz2)	bunzip2 "$1"				;;
	    *.rar)	unrar x "$1"				;;
	    *.gz)	tar xvf "$1"				;;
	    *.tar)	tar xvf "$1"				;;
	    *.tbz2)	tar xvjf "$1"				;;
	    *.tgz)	tar xvzf "$1"				;;
	    *.zip)	unzip "$1"				;;
	    *.Z)	uncompress "$1"				;;
	    *.7z)	7z x "$1"				;;
	    *)		echo "Unknown archive format: $1"	;;
	esac
    else
	echo "Not a valid file: $1"
    fi
}

# Check if current directory is a git repo
is_git_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
}

# Show current git  branch
git_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}
