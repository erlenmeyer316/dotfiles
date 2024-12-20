#!/usr/bin/env bash

# Where user-specific configurations should be written (analogous to /etc).
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:=$HOME/.config}"
# Where user-specific data files should be written (analogous to /usr/share).
export XDG_DATA_HOME="${XDG_DATA_HOME:=$HOME/.local/share}"
# Where user-specific non-essential (cached) data should be written (analogous to /var/cache).
export XDG_CACHE_HOME="${XDG_CACHE_HOME:=$HOME/.cache}"
# Where user-specific state files should be written (analogous to /var/lib).
export XDG_STATE_HOME="${XDG_STATE_HOME:=$HOME/.local/state}"

if [ -f "$XDG_CONFIG_HOME/user-dirs.dirs" ]; then
    source "$XDG_CONFIG_HOME/user-dirs.dirs"
fi
