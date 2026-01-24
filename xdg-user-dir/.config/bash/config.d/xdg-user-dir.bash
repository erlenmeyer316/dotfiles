if [ $(command -v "xdg-user-dir") ]; then
    if [ -f "$XDG_CONFIG_HOME/user-dirs.dirs" ]; then
        source "$XDG_CONFIG_HOME/user-dirs.dirs"
    fi
fi
