#!/usr/bin/env bash

# ===================================================================
# Script variables
# ===================================================================

readonly _SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
readonly _CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/dotfiles.conf"


# ===================================================================
# Utility functions
# ===================================================================

command_exists() { command -v "$1" >/dev/null 2>&1; }

file_exists() { [[ -f "$1" ]]; }

dir_exists() { [[ -d "$1" ]]; }
 
print_msg() { [[ "$_QUIET" -eq 0 ]] && printf "%s\n" "$1"; }

print_always() { printf "%s\n" "$1"; }

list_file_contents() { file_exists "$1" && cat -n "$1"; }

# ===================================================================
# User config
# ===================================================================

if file_exists "${_CONFIG_FILE}"; then
    source "${_CONFIG_FILE}"
fi

# ===================================================================
# Determine OS
# ===================================================================
case "$OSTYPE" in
  linux*)   _OS="Linux" ;;
  darwin*)  _OS="macOS" ;;
  msys*)    _OS="Windows" ;;
  cygwin*)  _OS="Cygwin" ;;
  solaris*) _OS="Solaris" ;;
  bsd*)     _OS="BSD" ;;
  *)        _OS="Unknown ($OSTYPE)" ;;
esac

# ===================================================================
# Determine Linux Distro
# ===================================================================
if [ "$_OS" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        # Load variables from /etc/os-release
        . /etc/os-release
        _DISTRO=$ID
        _VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # Fallback to lsb_release if /etc/os-release is missing
	_DISTRO=$(lsb_release -si)
        _VERSION=$(lsb_release -sr)
    else
        # Basic fallback for older or minimal systems
	_DISTRO=$(uname -s)
        _VERSION=$(uname -r)
    fi
fi

# ===================================================================
# Script constants
# ===================================================================

readonly _LIB_DIR="${_SCRIPT_DIR}/lib"
readonly _STOW_DIR="${DOTFILES_STOW_DIR:-${_SCRIPT_DIR}/stow}"
readonly _SETUP_DIR="${DOTFILES_SETUP_DIR:-${_SCRIPT_DIR}/setup}"
readonly _PROFILE_DIR="${DOTFILES_PROFILE_DIR:-${_SCRIPT_DIR}/profiles}"
readonly _INSTALL_DIR="${DOTFILES_DIR:-${SCRIPT_DIR}/install}"

