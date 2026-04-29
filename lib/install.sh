
#!/usr/bin/env bash


load_driver() {
    local install_dir "${1}"
    local driver="${install_dir}/${_NAME}/${_VERSION}/driver.sh"

}


# ===================================================================
# Apt helpers
# ===================================================================
package_installed() { dpkg -s "$1" &>/dev/null; }

apt_install_pkglist() {
    local pkglist="$1"
    file_exists "$pkglist" || return 0
    local packages=()
    while IFS= read -r pkg; do
        if package_installed "$pkg"; then
            print_msg "  ${pkg} already installed, skipping"
        else
            print_msg "  Queueing ${pkg}"
            packages+=("$pkg")
        fi
    done < "$pkglist"
    if [[ ${#packages[@]} -gt 0 ]]; then
        if [[ "$_DRY_RUN" -eq 1 ]]; then
            print_always "[dry-run] apt-get install -y ${packages[*]}"
        else
            sudo apt-get install -y "${packages[@]}"
        fi
    fi
}

apt_remove_pkglist() {
    local pkglist="$1"
    file_exists "$pkglist" || return 0

    # Collect only what is actually installed
    local packages=()
    while IFS= read -r pkg; do
        package_installed "$pkg" && packages+=("$pkg")
    done < "$pkglist"
    [[ ${#packages[@]} -eq 0 ]] && return 0

    # Always prompt — apt removal is never silent
    print_always ""
    print_always "The following packages will be removed:"
    for pkg in "${packages[@]}"; do
        print_always "  - ${pkg}"
    done
    print_always ""
    read -r -p "Proceed? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_always "Skipping apt removal."
        return 0
    fi

    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] apt-get remove -y ${packages[*]}"
    else
        sudo apt-get remove -y "${packages[@]}"
    fi
}

