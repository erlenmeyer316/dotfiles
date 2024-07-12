#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/helpers.sh
source "$CURRENT_DIR/helpers.sh"

time_format="12hr"

print_time(){
	time_format=$(get_tmux_option "@time_format" "$time_format")
	if [ "${time_format}" = "12hr" ]; then
		date +'%I:%M %p'
	else
		date
	fi
	
}

main() {
  print_time
}
main "$@"

