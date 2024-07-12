#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/scripts/helpers.sh"

widget_interpolation=(
  "\#{current_time_bg}"
  "\#{current_time_fg}"
  "\#{current_time}"
  "\#{current_date_bg}"
  "\#{current_date_fg}"
  "\#{current_date}"
  "\#{current_volume_bg}"
  "\#{current_volume_fg}"
  "\#{current_volume}"
  "\#{current_brightness}"
)
widget_commands=(
  "#($CURRENT_DIR/scripts/current_time_bg.sh)"
  "#($CURRENT_DIR/scripts/current_time_fg.sh)"
  "#($CURRENT_DIR/scripts/current_time.sh)"
  "#($CURRENT_DIR/scripts/current_date_bg.sh)"
  "#($CURRENT_DIR/scripts/current_date_fg.sh)"
  "#($CURRENT_DIR/scripts/current_date.sh)"
  "#($CURRENT_DIR/scripts/current_volume_bg.sh)"
  "#($CURRENT_DIR/scripts/current_volume_fg.sh)"
  "#($CURRENT_DIR/scripts/current_volume.sh)"
  "#($CURRENT_DIR/scripts/current_brightness.sh)"
)

set_tmux_option() {
  local option=$1
  local value=$2
  tmux set-option -gq "$option" "$value"
}

do_interpolation() {
  local all_interpolated="$1"
  for ((i = 0; i < ${#widget_commands[@]}; i++)); do
    all_interpolated=${all_interpolated//${widget_interpolation[$i]}/${widget_commands[$i]}}
  done
  echo "$all_interpolated"
}

update_tmux_option() {
  local option
  local option_value
  local new_option_value
  option=$1
  option_value=$(get_tmux_option "$option")
  new_option_value=$(do_interpolation "$option_value")
  set_tmux_option "$option" "$new_option_value"
  echo "$new_option_value"
}

main() {
  update_tmux_option "status-right"
  update_tmux_option "status-left"
}
main
