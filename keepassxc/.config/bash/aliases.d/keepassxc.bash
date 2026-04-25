if [ $(command -v "keepassxc-cli") ]; then
    # kp is the wrapper binary — see ~/.local/bin/kp and ~/.config/kp/
    # unlock/lock the vault keyring cache for the current session
    alias kplock="kp lock"
    alias kpunlock="kp unlock"
fi
