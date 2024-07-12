
#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/helpers.sh
source "$CURRENT_DIR/helpers.sh"

volume_format="Percent"

print_volume(){
  if command_exists "pamixer"; then
	volume_format=$(get_tmux_option "@volume_format" "$volume_format")
	if [ "${volume_format}" == "Percent" ]; then
		pamixer --get-volume-human
	else
		pamixer --get-volume
	fi
  else
      echo "missing pamixer"
  fi	
}

main() {
  print_volume
}
main "$@"
