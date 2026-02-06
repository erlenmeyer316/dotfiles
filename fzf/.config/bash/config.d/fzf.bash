if [ $(command -v "fzf") ]; then
    if [ -f "/usr/share/doc/fzf/examples/key-bindings.bash" ]; then
       source /usr/share/doc/fzf/examples/key-bindings.bash
    else
       eval "$(fzf --bash)"
    fi

    if [ $(command -v "rg") ]; then
        export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git'"
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi
