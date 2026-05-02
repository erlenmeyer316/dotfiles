#!/usr/bin/env bash
# ==============================================================================
# lib/drivers/apt.sh — APT package manager driver
#
# Implements the five-function driver contract for apt/dpkg systems
# (Debian, Ubuntu, and derivatives).
#
# Sourced by install.sh via load_driver. Do not execute directly.
# Requires core.sh to have been loaded (provides $_DRY_RUN, print_always).
# ==============================================================================


# ------------------------------------------------------------------------------
# pkg_update_repos
#
# Refreshes the apt package index (apt-get update).
# Called once before a batch install — not needed before removal.
# ------------------------------------------------------------------------------
pkg_update_repos() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] apt-get update"
        return 0
    fi
    sudo apt-get update
}


# ------------------------------------------------------------------------------
# pkg_install <pkg> [<pkg> ...]
#
# Batch installs one or more packages via apt-get.
# Receives a pre-filtered list — all packages have already been verified to
# exist in the repo and to not be currently installed.
# ------------------------------------------------------------------------------
pkg_install() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] apt-get install -y $*"
        return 0
    fi
    sudo apt-get install -y "$@"
}


# ------------------------------------------------------------------------------
# pkg_remove <pkg> [<pkg> ...]
#
# Batch removes one or more packages via apt-get.
# Receives a pre-filtered list of installed packages.
# User confirmation is handled by remove_binlist in install.sh — not here.
# ------------------------------------------------------------------------------
pkg_remove() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] apt-get remove -y $*"
        return 0
    fi
    sudo apt-get remove -y "$@"
}


# ------------------------------------------------------------------------------
# pkg_is_installed <pkg>
#
# Returns 0 if the package is currently installed according to dpkg, 1 if not.
# Called in a loop by install.sh to build the install/remove batch — must be fast.
# ------------------------------------------------------------------------------
pkg_is_installed() {
    dpkg -s "$1" &>/dev/null
}


# ------------------------------------------------------------------------------
# pkg_exists <pkg>
#
# Returns 0 if the package is available in the apt cache, 1 if not.
# Assumes pkg_update_repos has already been called in this session.
# ------------------------------------------------------------------------------
pkg_exists() {
    apt-cache show "$1" &>/dev/null
}
