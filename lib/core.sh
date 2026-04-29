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
 
print_msg() { [[ "$QUIET" -eq 0 ]] && printf "%s\n" "$1"; }

print_always() { printf "%s\n" "$1"; }

list_file_contents() { file_exists "$1" && cat -n "$1"; }

# ===================================================================
# User config
# ===================================================================

if file_exists "${_CONFIG_FILE}"; then
    source "${_CONFIG_FILE}"
fi

# ===================================================================
# Script constants
# ===================================================================

readonly _LIB_DIR="${_SCRIPT_DIR}/lib"
readonly _STOW_DIR="${DOTFILES_STOW_DIR:-${_SCRIPT_DIR}/stow}"
readonly _PACKAGES_DIR="${DOTFILES_PACKAGES_DIR:-${_SCRIPT_DIR}/packages}"
readonly _SETUP_DIR="${DOTFILES_SETUP_DIR:-${_SCRIPT_DIR}/setup}"
readonly _PROFILE_DIR="${DOTFILES_PROFILE_DIR:-${_SCRIPT_DIR}/profiles}"

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
if [ "$OS" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        # Load variables from /etc/os-release
        . /etc/os-release
        _tmpName="${NAME// /-}"
        _DISTRO_INTERNAL="${_tmpName////_}"
        _DISTRO=$NAME
        _VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # Fallback to lsb_release if /etc/os-release is missing
	_name=$(lsb_release -si)
	_tmpName="${_name// /-}"
	_DISTRO_INTERNAL="${_tmpName////_}"
	_DISTRO=$(lsb_release -si)
        _VERSION=$(lsb_release -sr)
    else
        # Basic fallback for older or minimal systems
        _name=$(uname -s)
	_tmpName="${_name// /-}"
	_DISTRO_INTERNAL="${_tmpName////_}"
	_DISTRO=$(uname -s)
        _VERSION=$(uname -r)
    fi
fi
