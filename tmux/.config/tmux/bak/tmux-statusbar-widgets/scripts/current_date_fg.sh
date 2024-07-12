#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/helpers.sh
source "$CURRENT_DIR/helpers.sh"

date_fg_color=""

date_default_fg_color="#[fg=white]"

get_fg_color_settings() {
  date_fg_color=$(get_tmux_option "@date_fg_color" "$date_default_fg_color")
}

print_fg_color() {
  echo "$date_fg_color"
}

main() {
  get_fg_color_settings
  print_fg_color
}
main "$@"
