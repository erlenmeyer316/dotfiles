#!/usr/bin/env bash

# ================================================================
# Stow helpers
# ================================================================

stow_pkg_exists() { dir_exists "${STOW_DIR}/${1}"; }


# Run stow on a single package directory.
# $1 = package name, $2 = stow action flag (-R relink | -D unlink)
run_stow() {
    local pkg="$1" action="${2:--R}"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] stow ${action} ${pkg}"
        return
    fi
    if [[ "$FORCE" -eq 1 ]]; then
        stow --adopt -d "${STOW_DIR}" -t ~ "${action}" "$pkg"
    else
        stow -d "${STOW_DIR}" -t ~ "${action}" "$pkg"
    fi
}

# Stow every package listed in a pkglist file
link_pkglist() {
    local pkglist="$1"
    file_exists "$pkglist" || return 0
    while IFS= read -r pkg; do
        print_msg "  Linking ${pkg}"
        run_stow "$pkg" -R
    done < "$pkglist"
}

# Unstow every package listed in a pkglist file
unlink_pkglist() {
    local pkglist="$1"
    file_exists "$pkglist" || return 0
    while IFS= read -r pkg; do
        print_msg "  Unlinking ${pkg}"
        run_stow "$pkg" -D
    done < "$pkglist"
}


