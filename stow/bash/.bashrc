# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Initialize moduler bash profile
if [ -f "$HOME/.config/bash/init.bash" ]; then
    . "$HOME/.config/bash/init.bash"
fi

# Initialize local bashrc
if [ -f "$HOME/.bashrc_local" ]; then
    . "$HOME/.bashrc_local"
fi
