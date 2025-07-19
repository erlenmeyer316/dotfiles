# Navigation & Listing
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias r='ranger'

# Git
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'

# Editors
alias v='nvim'

# Docker
alias d='docker'
alias dps='docker ps'
alias di='docker images'
alias dstop='docker stop $(docker ps -d)'
alias drm='docker rm $(docker ps -a -q)'
alias drmi='docker rmi $(docker images -q)'
alias dclean='docker system prune -af --volumes'
alias dlog='docker logs -f'
alias dexec='docker -exec -it'
alias dbash='docker exec -it \"$1\" /bin/bash'

# Lazy tools
alias lz='lazygit'
alias ld='lazydocker'

# Safer deletes
alias rm='trash-put'
