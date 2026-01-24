if [ $(command -v "ranger") ]; then
    ranger_cd() {
        temp_file="$(mktemp -t "ranger_cd.XXXXXXXXX")"
        ranger --choosedir="$temp_file" -- "${@:-$PWD}"
        if chosen_dir="$(cat -- "$temp_file")" && [ -n "$chosen_dir" ] && [ "$chosen_dir" != "$PWD" ]; then
            cd -- "$chosen_dir"
        fi
        rm -f -- "$temp_file"
    }
fi
