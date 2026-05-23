#!/usr/bin/env bash

shopt -s nullglob

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/core.sh"

source "${_LIB_DIR}/profiles.sh"
source "${_LIB_DIR}/stow.sh"
source "${_LIB_DIR}/setup.sh"
source "${_LIB_DIR}/install.sh"


# Targets — populated during flag parsing
_PROFILES_INPUT=()    # profiles explicitly requested via -p
_SETUPS_INPUT=()      # setups requested via -s
_STOW_INPUT=()        # individual stow packages requested via -pkg
_INSTALL_PROFILES=()  # fully resolved profile list (after dep expansion)

# Flags
_FORCE=0
_QUIET=0
_DRY_RUN=0

mapfile -t _ALL_SETUPS < <(ls "${_SETUP_DIR}")
mapfile -t _ALL_PROFILES < <(ls "${_PROFILE_DIR}")

# ===================================================================
# Internal shared work — called by public subcommand functions
# ===================================================================

# Core symlink work used by both 'link' and 'install'
_do_link() {
    # --force requires a clean working tree to avoid silent data loss
    if [[ "$_FORCE" -eq 1 ]]; then
        if ! git -C "${_SCRIPT_DIR}" diff --quiet; then
            print_always "Error: repo has uncommitted changes. Aborting --force."
            print_always "Review with: git -C ${_SCRIPT_DIR} diff"
            exit 1
        fi
    fi

    resolve_profiles "${_PROFILE_DIR}" _PROFILES_INPUT _INSTALL_PROFILES

    for profile in "${_INSTALL_PROFILES[@]}"; do
        print_msg "Linking profile: ${profile}"
        link_pkglist "${_STOW_DIR}" "${_PROFILE_DIR}/${profile}/stow.pkglist" "${_DRY_RUN}" "${_FORCE}"
    done

    # Restore dotfile versions after --adopt may have pulled in local files
    [[ "$_FORCE" -eq 1 ]] && git -C "${_SCRIPT_DIR}" reset --hard

    for pkg in "${_STOW_INPUT[@]}"; do
        print_msg "Linking package: ${pkg}"
        run_stow "${_STOW_DIR}" "$pkg" -R "${_DRY_RUN}" "${_FORCE}"
    done
}

# Core unsymlink work used by both 'unlink' and 'remove'
_do_unlink() {
    resolve_profiles "${_PROFILE_DIR}" _PROFILES_INPUT _INSTALL_PROFILES

    for profile in "${_INSTALL_PROFILES[@]}"; do
        print_msg "Unlinking profile: ${profile}"
        unlink_pkglist "${_STOW_DIR}" "${_PROFILE_DIR}/${profile}/stow.pkglist" "${_DRY_RUN}" "${_FORCE}"
    done

    for pkg in "${_STOW_INPUT[@]}"; do
        print_msg "Unlinking package: ${pkg}"
        run_stow "${_STOW_DIR}" "$pkg" -D "${_DRY_RUN}" "${_FORCE}"
    done
}


finish_msg() {
    if file_exists "$HOME/.profile"; then
        print_msg ""
        print_msg "----------------------------------------------------------------"
        print_msg "Done! Run 'source ~/.profile' to apply changes."
    fi
}

# ===================================================================
# Subcommands
# ===================================================================

cmd_link() {
    _do_link
    finish_msg
}

cmd_unlink() {
    _do_unlink
}

cmd_install() {
	
    resolve_profiles "${_PROFILE_DIR}" _PROFILES_INPUT _INSTALL_PROFILES

    for profile in "${_INSTALL_PROFILES[@]}"; do
	execute_pre_link_setups "${_SETUP_DIR}" "${_PROFILE_DIR}/${profile}/setups.pkglist"
    done

    _do_link

    for profile in "${_INSTALL_PROFILES[@]}"; do
	execute_pre_install_setups "${_SETUP_DIR}" "${_PROFILE_DIR}/${profile}/setups.pkglist"
    done

    print_msg ""
    print_msg "Updating package repositories..."

    for profile in "${_INSTALL_PROFILES[@]}"; do
        print_msg "Installing apt packages for: ${profile}"
        install_binlist "${_PROFILE_DIR}/${profile}/${_DISTRO}-${_VERSION}.binlist"

    done

    for profile in "${_INSTALL_PROFILES[@]}"; do
	execute_post_install_setups "${_SETUP_DIR}" "${_PROFILE_DIR}/${profile}/setups.pkglist"
    done
    finish_msg
}

cmd_remove() {
    # Unlink first, then offer apt removal
    _do_unlink

    for profile in "${_INSTALL_PROFILES[@]}"; do
        remove_binlist "${_PROFILE_DIR}/${profile}/${_DISTRO}-${_VERSION}.binlist"
    done

}

cmd_list() {
    local sub="$1"

    case "$sub" in
        profiles)
            print_always "Available profiles:"
            printf "  %s\n" "${_ALL_PROFILES[@]}"
            ;;
        packages)
            resolve_profiles "${_PROFILE_DIR}" _PROFILES_INPUT _INSTALL_PROFILES
            for profile in "${_INSTALL_PROFILES[@]}"; do
                print_always "Profile '${profile}' stow packages:"
                list_file_contents "${_PROFILE_DIR}/${profile}/stow.pkglist"
            done
            for pkg in "${_STOW_INPUT[@]}"; do
                print_always "Package '${pkg}':"
                if dir_exists "${_STOW_DIR}/${pkg}"; then
                    ls "${_STOW_DIR}/${pkg}"
                else
                    print_always "  (not found in repo)"
                fi
            done
            ;;
        binaries)
            resolve_profiles "${_PROFILE_DIR}" _PROFILES_INPUT _INSTALL_PROFILES
            for profile in "${_INSTALL_PROFILES[@]}"; do
                print_always "Profile '${profile}' apt packages:"
                list_file_contents "${_PROFILE_DIR}/${profile}/${_DISTRO}-${_VERSION}.binlist"
            done
            ;;
        "")
            print_always "Error: 'list' requires a sub-action."
            print_always "Usage: $(basename "$0") list <profiles|packages|binaries> [-p PROFILE|-pkg PKG]"
            exit 1
            ;;
        *)
            print_always "Error: unknown list target '${sub}'."
            print_always "Usage: $(basename "$0") list <profiles|packages|binaries> [-p PROFILE|-pkg PKG]"
            exit 1
            ;;
    esac
}

cmd_doctor() {
    local broken=()
    find_broken_symlinks broken "$DOCTOR_SEARCH_DEPTH"

    if [[ ${#broken[@]} -eq 0 ]]; then
        print_always "No broken symlinks found."
        return 0
    fi

    print_always "Broken symlinks found:"
    printf "  %s\n" "${broken[@]}"

    [[ "$1" != "--fix" ]] && return 0

    print_always ""
    read -r -p "Remove all of the above? [y/N] " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && return 0

    for link in "${broken[@]}"; do
        [[ "$_DRY_RUN" -eq 1 ]] && print_always "[dry-run] rm ${link}" && continue
        rm "$link"
    done
}

# ===================================================================
# Usage
# ===================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") <subcommand> [targets] [options]

Subcommands:
  link      Symlink dotfiles via stow 
  unlink    Remove stow symlinks 
  install   Symlink dotfiles + install apt packages
  remove    Remove stow symlinks + remove apt packages
  list      Query profiles, packages + setups
  doctor    Find and remove broken symlinks

Targets (repeatable, combinable):
  -p  PROFILE   Operate on a profile (resolves dependencies)
  -pkg PKG      Operate on a single stow package

Options:
  -f    Force overwrite existing dotfiles (stow --adopt + git reset)
  -q    Quiet — suppress informational output
  -d    Dry run — print what would happen, do nothing
  -h    Show this help
  --fix Fix broken symlinnks

List usage:
  $(basename "$0") list profiles
  $(basename "$0") list packages  -p PROFILE [-p PROFILE ...]
  $(basename "$0") list packages  -pkg PKG   [-pkg PKG ...]
  $(basename "$0") list binaries  -p PROFILE [-p PROFILE ...]

Examples:
  $(basename "$0") install -p term
  $(basename "$0") install -p base -p dev-tools
  $(basename "$0") link    -pkg ranger -pkg tmux
  $(basename "$0") unlink  -p term-x11
  $(basename "$0") remove  -p dev-tools
  $(basename "$0") list    profiles
  $(basename "$0") list    packages -p base
  $(basename "$0") list    binaries -p term
  $(basename "$0") install -p term -d
  $(basename "$0") doctor --fix"
EOF
}

# ===================================================================
# Entry point
# ===================================================================

if ! command_exists stow; then
    print_always "Error: stow not installed."
    exit 1
fi

if [[ "$#" -eq 0 ]]; then
    print_always "Error: no subcommand given."
    usage
    exit 1
fi

_SUBCOMMAND="$1"
shift

# For 'list', consume the sub-action before general flag parsing
_LIST_SUB=""
if [[ "$_SUBCOMMAND" == "list" && "${1:-}" != -* && -n "${1:-}" ]]; then
    _LIST_SUB="$1"
    shift
fi

# Parse flags and targets
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p)
            [[ -z "${2:-}" ]] && { print_always "Error: -p requires an argument."; exit 1; }
            _PROFILES_INPUT+=("$2")
            shift 2
            ;;
        -pkg)
            [[ -z "${2:-}" ]] && { print_always "Error: -pkg requires an argument."; exit 1; }
            _STOW_INPUT+=("$2")
            shift 2
            ;;
        -f) _FORCE=1;   shift ;;
        -q) _QUIET=1;   shift ;;
        -d) _DRY_RUN=1; shift ;;
        -h) usage; exit 0 ;;
        *)
            print_always "Error: unknown argument '$1'."
            print_always ""
            usage
            exit 1
            ;;
    esac
done

# Validate all profiles exist before doing any work
for profile in "${_PROFILES_INPUT[@]}"; do
    if ! profile_exists "${_PROFILE_DIR}" "$profile"; then
        print_always "Error: profile '${profile}' does not exist."
        exit 1
    fi
done

# Validate all stow packages exist before doing any work
for pkg in "${_STOW_INPUT[@]}"; do
    if ! stow_pkg_exists "${_STOW_DIR}" "$pkg"; then
        print_always "Error: stow package '${pkg}' does not exist."
        exit 1
    fi
done


# Require at least one target for action subcommands
case "$_SUBCOMMAND" in
    link|unlink)
         if [[  ${#_STOW_INPUT[@]} -eq 0  ]]; then
	     print_always "Error: '${_SUBCOMMAND}' requires at least one -pkg target."
             print_always ""
             usage
             exit 1
         fi
         ;;
    install|remove)
         if [[ ${#_PROFILES_INPUT[@]} -eq 0 ]]; then
             print_always "Error: '${_SUBCOMMAND}' requires at least one -p target."
             print_always ""
             usage
             exit 1
         fi
         ;;
esac

# Dispatch
case "$_SUBCOMMAND" in
    link)    cmd_link ;;
    unlink)  cmd_unlink ;;
    install) cmd_install ;;
    remove)  cmd_remove ;;
    list)    cmd_list "$_LIST_SUB" ;;
    doctor)  cmd_doctor ;;
    -h|--help) usage; exit 0 ;;
    *)
        print_always "Error: unknown subcommand '${_SUBCOMMAND}'."
        print_always ""
        usage
        exit 1
        ;;
esac
