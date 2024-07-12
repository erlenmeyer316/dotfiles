
#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/helpers.sh
source "$CURRENT_DIR/helpers.sh"

brightness_format="Percent"

print_brightness(){
  if command_exists "brightnessctl"; then
	brigntess_format=$(get_tmux_option "@brightness_format" "$brightness_format")
	if [ "${brightness_format}" == "Percent" ]; then
		brightnessctl -m | cut -d, -f4
	else
		brightnessctl -m | cut -d, -f4 | tr -d %
	fi
  else
      echo "missing brightnessctl"
  fi	
}

main() {
  print_brightness
}
main "$@"
