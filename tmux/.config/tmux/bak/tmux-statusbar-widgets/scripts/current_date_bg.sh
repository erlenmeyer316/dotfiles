#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/helpers.sh
source "$CURRENT_DIR/helpers.sh"

date_bg_color=""

date_default_bg_color="#[bg=blue]"

get_bg_color_settings() {
  date_bg_color=$(get_tmux_option "@date_bg_color" "$date_default_bg_color")
}

print_bg_color() {
  echo "$date_bg_color"
}

main() {
  get_bg_color_settings
  print_bg_color
}
main "$@"
