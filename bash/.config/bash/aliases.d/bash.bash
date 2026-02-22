
######################
# Aliases
#######################

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

alias ll='ls -alh'
alias la='ls -A'
alias l='ls -CF'

alias mkdir="mkdir -p"
alias home="cd $HOME"
alias ..="cd .."
