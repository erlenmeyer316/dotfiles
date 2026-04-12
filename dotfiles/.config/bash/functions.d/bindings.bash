bindings() {
  local tool="${1:-all}"

  _section() { printf '\n\033[1;35m=== %s ===\033[0m\n' "$1"; }

  case "$tool" in
    tmux|all)
      _section "tmux"
      tmux list-keys 2>/dev/null | grep -v '^#'
      ;;&
     i3|all)
       _section "i3"
       grep -E '^s*bindsym' ~/.config/i3/config 2>/dev/null \ | sed 's/^\s*bindsym\s*//'
       ;;&
     ranger|all)
       _section "ranger"
       grep -E '^\s*map\s' ~/.config/ranger/rc.conf 2>/dev/null \ | sed 's/^\s*map\s*//'
       ;;&
     w3m|all)
      _section "w3m"
      grep -v '^s*#' ~/.config/w3m/keymap 2>/dev/null \ | grep -v '^\s*$'
      ;;&
     nvim|all)
       _section "nvim (user mappings)"
       # Filters out runtime/plugin maps - only my config
       nvim --headless \
         -c 'rdir! > /tmp/.nvim-maps' \
	 -c 'map' \
	 -c 'redir END' \
	 -c 'qa' 2>/dev/null
       grep -v '^s*$' /tmp/.nvim-maps 2>/dev/null
       rm -f /tmp/.nvim-maps
       ;;
  esac	  
}
