#!/usr/bin/env bash

pkg_update_repos() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] flatpak update --appstream -y"
        return 0
    fi
    flatpak update --appstream -y 2>/dev/null || true
}


pkg_install() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] flatpak install -y $*"
        return 0
    fi
    flatpak install -y "$@"
}


pkg_remove() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] flatpak uninstall -y $*"
        return 0
    fi
    flatpak uninstall -y "$@"
}


pkg_is_installed() {
    flatpak info "$1" &>/dev/null
}


pkg_exists() {
    flatpak search --columns=application "$1" 2>/dev/null \
        | grep -qxF "$1"
}
