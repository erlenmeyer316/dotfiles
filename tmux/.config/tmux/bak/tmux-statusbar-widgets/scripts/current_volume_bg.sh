#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/helpers.sh
source "$CURRENT_DIR/helpers.sh"

volume_bg_color=""

volume_default_bg_color="#[bg=red]"

get_bg_color_settings() {
  volume_bg_color=$(get_tmux_option "@volume_bg_color" "$volume_default_bg_color")
}

print_bg_color() {
  echo "$volume_bg_color"
}

main() {
  get_bg_color_settings
  print_bg_color
}
main "$@"
