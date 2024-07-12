#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/helpers.sh
source "$CURRENT_DIR/helpers.sh"

time_bg_color=""

time_default_bg_color="#[bg=cyan]"

get_bg_color_settings() {
  time_bg_color=$(get_tmux_option "@time_bg_color" "$time_default_bg_color")
}

print_bg_color() {
  echo "$time_bg_color"
}

main() {
  get_bg_color_settings
  print_bg_color
}
main "$@"
