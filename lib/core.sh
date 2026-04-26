#!/usr/bin/env bash

# ===================================================================
# Script variables
# ===================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
readonly CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/dotfiles.conf"


# ===================================================================
# Utility functions
# ===================================================================

command_exists() { command -v "$1" >/dev/null 2>&1; }

file_exists() { [[ -f "$1" ]]; }

dir_exists() { [[ -d "$1" ]]; }
 
print_msg() { [[ "$QUIET" -eq 0 ]] && printf "%s\n" "$1"; }

print_always() { printf "%s\n" "$1"; }

list_file_contents() { file_exists "$1" && cat -n "$1"; }

# ===================================================================
# User config
# ===================================================================

if file_exists "${CONFIG_FILE}"; then
    source "${CONFIG_FILE}"
fi

# ===================================================================
# Script constants
# ===================================================================

readonly LIB_DIR="${SCRIPT_DIR}/lib"
readonly STOW_DIR="${DOTFILES_STOW_DIR:-${SCRIPT_DIR}/stow}"
readonly PACKAGES_DIR="${DOTFILES_PACKAGES_DIR:-${SCRIPT_DIR}/packages}"
readonly SETUP_DIR="${DOTFILES_SETUP_DIR:-${SCRIPT_DIR}/setup}"
readonly PROFILE_DIR="${DOTFILES_PROFILE_DIR:-${SCRIPT_DIR}/profiles}"

