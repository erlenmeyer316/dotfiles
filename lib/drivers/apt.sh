#!/usr/bin/env bash

pkg_update_repos() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] apt-get update"
        return 0
    fi
    sudo apt-get update
}


pkg_install() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] apt-get install -y $*"
        return 0
    fi
    sudo apt-get install -y "$@"
}


pkg_remove() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] apt-get remove -y $*"
        return 0
    fi
    sudo apt-get remove -y "$@"
}


pkg_is_installed() {
    dpkg -s "$1" &>/dev/null
}


pkg_exists() {
    apt-cache show "$1" &>/dev/null
}
