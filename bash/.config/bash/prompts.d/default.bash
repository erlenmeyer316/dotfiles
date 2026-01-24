# user@host:~/current/dir [branch] $
parse_git_branch() {
   git branch 2>/dev/null | grep '^*' | sed 's/^* //'
}

PS1='[\u@\h \[\e[33m\]\w\[\e[0m\]]'
PS1+='$(parse_git_branch | sed "s/.*/ (\e[35m&\e[0m)/")'
PS1+=' \s '
