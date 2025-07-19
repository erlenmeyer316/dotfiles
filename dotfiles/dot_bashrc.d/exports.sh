#
# ~/.bashrc.d/export.sh
#

# XDG Base Directory Specifications
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Encourage apps to follow XDG (fallback behavior for some older tools
export HISTFILE="${XDG_STATE_HOME}/bash/history"
export LESSHISTFILE="${XDG_STATE_HOME}/less_history"
export GNUPGHOME="${XDG_DATA_HOME/gnupg}"
export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}/bat/config"
export FZF_CONFIG="${XDG_CONFIG_HOME}/fzf/fzf.bash"

# Preferred editor
export EDITOR="nvim"
export VISUAL="nvim"

# PATH customizations
export PATH="$HOME/bin:$PATH"

# Enabled colors for core utilities
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabafaced

# Less options (better viewing)
export LESS='-R'
export LESSOPEN='|~/.lessfilter %s'

# FZF config (if installed)
export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Set locale 
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
