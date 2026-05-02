#!/usr/bin/env bash

declare -gA _PM_BATCHES

_parse_binlist() {
    local binlist="$1"

    # Reset for this parse pass
    unset _PM_BATCHES
    declare -gA _PM_BATCHES

    file_exists "$binlist" || return 0

    while IFS=: read -r pm pkg; do
        # Strip whitespace from both fields
        pm="${pm//[[:space:]]/}"
        pkg="${pkg//[[:space:]]/}"

        # Skip blank lines, comments, and malformed lines
        [[ -z "$pm" || "${pm:0:1}" == "#" || -z "$pkg" ]] && continue

        # Accumulate space-separated packages per PM
        _PM_BATCHES["$pm"]+="${_PM_BATCHES[$pm]:+ }${pkg}"
    done < "$binlist"
}


load_driver() {
    local pm="$1"
    local driver="${_LIB_DIR}/drivers/${pm}.sh"

    if [[ ! -f "$driver" ]]; then
        print_always "Error: no driver for package manager '${pm}' (expected: ${driver})"
        return 1
    fi

    source "$driver"
}


install_binlist() {
    local binlist="$1"

    if ! file_exists "$binlist"; then
        print_msg "No binlist at ${binlist} — skipping."
        return 0
    fi

    _parse_binlist "$binlist"

    if [[ ${#_PM_BATCHES[@]} -eq 0 ]]; then
        print_msg "Binlist is empty — nothing to install."
        return 0
    fi

    for pm in "${!_PM_BATCHES[@]}"; do
        print_msg ""
        print_msg "[${pm}] Loading driver..."
        load_driver "$pm" || continue

        # Step 1: refresh index — required before pkg_exists gives accurate results
        print_msg "[${pm}] Refreshing package index..."
        pkg_update_repos

        # Step 2: pre-flight — verify each package is available in the repo
        local available=()
        for pkg in ${_PM_BATCHES[$pm]}; do
            if pkg_exists "$pkg"; then
                available+=("$pkg")
            else
                print_always "Warning: [${pm}] '${pkg}' not found in repository — skipping."
            fi
        done
        [[ ${#available[@]} -eq 0 ]] && continue

        # Step 3: filter — skip packages already present on this machine
        local to_install=()
        for pkg in "${available[@]}"; do
            if ! pkg_is_installed "$pkg"; then
                #print_msg "  [${pm}] ${pkg} already installed — skipping."
            #else
                print_msg "  [${pm}] Queuing ${pkg}"
                to_install+=("$pkg")
            fi
        done

        if [[ ${#to_install[@]} -eq 0 ]]; then
            print_msg "[${pm}] All packages already installed."
            continue
        fi

        # Step 4: batch install
        print_msg "[${pm}] Installing: ${to_install[*]}"
        pkg_install "${to_install[@]}"
    done
}


remove_binlist() {
    local binlist="$1"

    if ! file_exists "$binlist"; then
        print_msg "No binlist at ${binlist} — skipping."
        return 0
    fi

    _parse_binlist "$binlist"

    if [[ ${#_PM_BATCHES[@]} -eq 0 ]]; then
        print_msg "Binlist is empty — nothing to remove."
        return 0
    fi

    for pm in "${!_PM_BATCHES[@]}"; do
        load_driver "$pm" || continue

        # Collect only what is actually installed
        local to_remove=()
        for pkg in ${_PM_BATCHES[$pm]}; do
            pkg_is_installed "$pkg" && to_remove+=("$pkg")
        done

        if [[ ${#to_remove[@]} -eq 0 ]]; then
            print_msg "[${pm}] No installed packages to remove."
            continue
        fi

        # Always prompt — removal is never silent regardless of -q
        print_always ""
        print_always "[${pm}] The following packages will be removed:"
        printf "    - %s\n" "${to_remove[@]}"
        print_always ""
        read -r -p "Proceed with [${pm}] removal? [y/N] " confirm
        [[ ! "$confirm" =~ ^[Yy]$ ]] && { print_always "Skipping [${pm}] removal."; continue; }

        pkg_remove "${to_remove[@]}"
    done
}
