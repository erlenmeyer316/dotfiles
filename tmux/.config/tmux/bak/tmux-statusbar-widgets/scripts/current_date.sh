
#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/helpers.sh
source "$CURRENT_DIR/helpers.sh"

date_format="Short"

print_date(){
	date_format=$(get_tmux_option "@date_format" "$date_format")
	if [ "${date_format}" == "Short" ]; then
		date +'%a %m-%d'
	else
		date -I
	fi
	
}

main() {
  print_date
}
main "$@"
