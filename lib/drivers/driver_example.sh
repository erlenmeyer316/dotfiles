#!/usr/bin/env bash
# ==============================================================================
# DRIVER CONTRACT STUB — copy this file to lib/drivers/<pm>.sh
#
# Each driver implements exactly the five functions below for a single package
# manager. install.sh sources one driver at a time, calls its functions for
# that PM's batch, then sources the next driver. Function names are fixed —
# do not prefix or rename them.
#
# Calling conventions:
#   - All functions receive packages as separate positional arguments ("$@")
#   - All functions return 0 on success, non-zero on failure
#   - Drivers are silent on success; errors go to stderr
#   - Drivers are non-interactive — no prompts, no confirm dialogs
#   - All user-facing messaging and prompting lives in install.sh, not here
#   - Dry-run awareness: drivers must respect the $_DRY_RUN flag (set by
#     install.sh before sourcing). When $_DRY_RUN=1, print the command that
#     would run but do not execute it.
#
# Sourcing:
#   Drivers are sourced by install.sh, which has already sourced core.sh.
#   The following variables are therefore available to every driver:
#     $_DRY_RUN   — 1 if dry-run mode is active
#     $_QUIET     — 1 if quiet mode is active
#     $print_msg  — use print_msg / print_always for any output
# ==============================================================================


# ------------------------------------------------------------------------------
# pkg_update_repos
#
# Refresh the package manager's local index / metadata cache.
# Called once per PM before pkg_install, never called before pkg_remove.
#
# Arguments: none
# Returns:   0 on success, non-zero on failure
# ------------------------------------------------------------------------------
pkg_update_repos() {
    # Example (apt):
    # if [[ "$_DRY_RUN" -eq 1 ]]; then
    #     print_always "[dry-run] apt-get update"
    #     return 0
    # fi
    # sudo apt-get update
    :
}


# ------------------------------------------------------------------------------
# pkg_install
#
# Batch-install one or more packages in a single PM invocation.
# install.sh is responsible for filtering the list down to only packages that
# are not already installed (via pkg_is_installed) before calling this.
# This function should never be called with an empty argument list.
#
# Arguments: pkg_install <pkg> [<pkg> ...]
# Returns:   0 on success, non-zero on failure
# ------------------------------------------------------------------------------
pkg_install() {
    # Example (apt):
    # if [[ "$_DRY_RUN" -eq 1 ]]; then
    #     print_always "[dry-run] apt-get install -y $*"
    #     return 0
    # fi
    # sudo apt-get install -y "$@"
    :
}


# ------------------------------------------------------------------------------
# pkg_remove
#
# Batch-remove one or more packages in a single PM invocation.
# install.sh is responsible for filtering the list down to only packages that
# are currently installed (via pkg_is_installed) and for prompting the user
# for confirmation before calling this.
# This function should never be called with an empty argument list.
#
# Arguments: pkg_remove <pkg> [<pkg> ...]
# Returns:   0 on success, non-zero on failure
# ------------------------------------------------------------------------------
pkg_remove() {
    # Example (apt):
    # if [[ "$_DRY_RUN" -eq 1 ]]; then
    #     print_always "[dry-run] apt-get remove -y $*"
    #     return 0
    # fi
    # sudo apt-get remove -y "$@"
    :
}


# ------------------------------------------------------------------------------
# pkg_is_installed
#
# Test whether a single package is currently installed on this machine.
# Used by install.sh to build the filtered batch before calling pkg_install
# or pkg_remove. Must be callable in a tight loop — keep it fast.
#
# Arguments: pkg_is_installed <pkg>
# Returns:   0 if installed, 1 if not installed
# ------------------------------------------------------------------------------
pkg_is_installed() {
    # Example (apt):
    # dpkg -s "$1" &>/dev/null
    :
}


# ------------------------------------------------------------------------------
# pkg_exists
#
# Test whether a single package is available in the PM's repository.
# Used by install.sh for pre-flight validation — called before building the
# install batch so unavailable packages can be reported cleanly rather than
# failing mid-install.
# Assumes pkg_update_repos has already been called in this session.
#
# Arguments: pkg_exists <pkg>
# Returns:   0 if available, 1 if not found
# ------------------------------------------------------------------------------
pkg_exists() {
    # Example (apt):
    # apt-cache show "$1" &>/dev/null
    :
}
