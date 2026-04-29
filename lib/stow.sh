#!/usr/bin/env bash

# ================================================================

stow_pkg_exists() { 
    local stow_dir="$1" pkg="$2"
    dir_exists "${stow_dir}/${pkg}";
}


# Run stow on a single package directory.
# $1 = stow directory, $2 = package name, $3 = stow action flag (-R relink | -D unlink), $4 = dry_run flag, $5 = force flag
run_stow() {
    local stow_dir="$1" pkg="$2" action="${3:--R}" dry_run="$4" force="$5"
    if [[ "$dry_run" -eq 1 ]]; then
        print_always "[dry-run] stow ${action} ${pkg}"
        return
    fi
    if [[ "$force" -eq 1 ]]; then
        stow --adopt -d "${stow_dir}" -t ~ "${action}" "$pkg"
    else
        stow -d "${stow_dir}" -t ~ "${action}" "$pkg"
    fi
}

# Stow every package listed in a pkglist file
link_pkglist() {
    local stow_dir="$1" pkglist="$2" dry_run="$3" force="$4"
    file_exists "$pkglist" || return 0
    while IFS= read -r pkg; do
        print_msg "  Linking ${pkg}"
        run_stow "$stow_dir" "$pkg" -R "${dry_run}" "${force}"
    done < "$pkglist"
}

# Unstow every package listed in a pkglist file
unlink_pkglist() {
    local stow_dir="$1" pkglist="$2" dry_run="$3" force="$4"
    file_exists "$pkglist" || return 0
    while IFS= read -r pkg; do
        print_msg "  Unlinking ${pkg}"
        run_stow "$stow_dir" "$pkg" -R "${dry_run}" "${force}"
    done < "$pkglist"
}

find_broken_symlinks() {
    local -n _broken="$1"
    local search_dir="${2:-$HOME}"
    local search_depth="$3:-"4"}"
    while IFS= read -r link; do
        _broken+=("$link")
    done < <(find "$search_dir" -maxdepth "$search_depth" -xtype l 2>/dev/null)
}
