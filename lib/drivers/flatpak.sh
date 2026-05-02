#!/usr/bin/env bash
# ==============================================================================
# lib/drivers/flatpak.sh — Flatpak driver
#
# Implements the five-function driver contract for Flatpak.
# Package identifiers must be fully-qualified application IDs,
# e.g. org.mozilla.firefox, com.spotify.Client.
#
# Sourced by install.sh via load_driver. Do not execute directly.
# Requires core.sh to have been loaded (provides $_DRY_RUN, print_always).
#
# Prerequisites on the target machine:
#   - flatpak installed and available in PATH
#   - at least one remote configured (typically flathub)
#     To add flathub: flatpak remote-add --if-not-exists flathub \
#                       https://dl.flathub.org/repo/flathub.flatpakrepo
# ==============================================================================


# ------------------------------------------------------------------------------
# pkg_update_repos
#
# Refreshes Flatpak appstream metadata from all configured remotes.
# Uses --appstream to refresh index only — does not update installed apps.
#
# Note: --appstream was deprecated in flatpak >= 1.15. On those versions this
# command exits non-zero but metadata is refreshed automatically on the next
# remote operation. The || true absorbs that harmless failure.
# ------------------------------------------------------------------------------
pkg_update_repos() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] flatpak update --appstream -y"
        return 0
    fi
    flatpak update --appstream -y 2>/dev/null || true
}


# ------------------------------------------------------------------------------
# pkg_install <pkg> [<pkg> ...]
#
# Batch installs one or more Flatpak applications.
# Receives a pre-filtered list — all packages have been verified to exist
# and to not be currently installed.
# ------------------------------------------------------------------------------
pkg_install() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] flatpak install -y $*"
        return 0
    fi
    flatpak install -y "$@"
}


# ------------------------------------------------------------------------------
# pkg_remove <pkg> [<pkg> ...]
#
# Batch removes one or more Flatpak applications.
# User confirmation is handled by remove_binlist in install.sh — not here.
# ------------------------------------------------------------------------------
pkg_remove() {
    if [[ "$_DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] flatpak uninstall -y $*"
        return 0
    fi
    flatpak uninstall -y "$@"
}


# ------------------------------------------------------------------------------
# pkg_is_installed <pkg>
#
# Returns 0 if the application is currently installed, 1 if not.
# Matches against the full application ID (e.g. org.mozilla.firefox).
# ------------------------------------------------------------------------------
pkg_is_installed() {
    flatpak info "$1" &>/dev/null
}


# ------------------------------------------------------------------------------
# pkg_exists <pkg>
#
# Returns 0 if the application ID is available in any configured remote, 1 if not.
# Uses `flatpak search` against local appstream data (refreshed by pkg_update_repos).
# Filters the application-ID column for an exact match to avoid false positives
# from substring matches in package descriptions.
# ------------------------------------------------------------------------------
pkg_exists() {
    flatpak search --columns=application "$1" 2>/dev/null \
        | grep -qxF "$1"
}
