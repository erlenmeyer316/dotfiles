#!/usr/bin/env bash

shopt -s nullglob

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/core.sh"

source "${LIB_DIR}/profiles.sh"
source "${LIB_DIR}/stow.sh"
source "${LIB_DIR}/setup.sh"

# Targets — populated during flag parsing
PROFILES_INPUT=()    # profiles explicitly requested via -p
SETUPS_INPUT=()      # setups requested via -s
STOW_PKGS=()         # individual stow packages requested via -pkg
INSTALL_PROFILES=()  # fully resolved profile list (after dep expansion)

# Flags
FORCE=0
QUIET=0
DRY_RUN=0

# ===================================================================
# Apt helpers
# ===================================================================
package_installed() { dpkg -s "$1" &>/dev/null; }

apt_install_pkglist() {
    local pkglist="$1"
    file_exists "$pkglist" || return 0
    local packages=()
    while IFS= read -r pkg; do
        if package_installed "$pkg"; then
            print_msg "  ${pkg} already installed, skipping"
        else
            print_msg "  Queueing ${pkg}"
            packages+=("$pkg")
        fi
    done < "$pkglist"
    if [[ ${#packages[@]} -gt 0 ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
            print_always "[dry-run] apt-get install -y ${packages[*]}"
        else
            sudo apt-get install -y "${packages[@]}"
        fi
    fi
}

apt_remove_pkglist() {
    local pkglist="$1"
    file_exists "$pkglist" || return 0

    # Collect only what is actually installed
    local packages=()
    while IFS= read -r pkg; do
        package_installed "$pkg" && packages+=("$pkg")
    done < "$pkglist"
    [[ ${#packages[@]} -eq 0 ]] && return 0

    # Always prompt — apt removal is never silent
    print_always ""
    print_always "The following packages will be removed:"
    for pkg in "${packages[@]}"; do
        print_always "  - ${pkg}"
    done
    print_always ""
    read -r -p "Proceed? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_always "Skipping apt removal."
        return 0
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] apt-get remove -y ${packages[*]}"
    else
        sudo apt-get remove -y "${packages[@]}"
    fi
}

# ===================================================================
# Internal shared work — called by public subcommand functions
# ===================================================================

# Core symlink work used by both 'link' and 'install'
_do_link() {
    # --force requires a clean working tree to avoid silent data loss
    if [[ "$FORCE" -eq 1 ]]; then
        if ! git -C "${SCRIPT_DIR}" diff --quiet; then
            print_always "Error: repo has uncommitted changes. Aborting --force."
            print_always "Review with: git -C ${SCRIPT_DIR} diff"
            exit 1
        fi
    fi

    resolve_profiles PROFILES_INPUT INSTALL_PROFILES

    for profile in "${INSTALL_PROFILES[@]}"; do
        print_msg "Linking profile: ${profile}"
        link_pkglist "${PROFILE_DIR}/${profile}/stow.pkglist" "${DRY_RUN}" "${FORCE}"
    done

    # Restore dotfile versions after --adopt may have pulled in local files
    [[ "$FORCE" -eq 1 ]] && git -C "${SCRIPT_DIR}" reset --hard

    for pkg in "${STOW_PKGS[@]}"; do
        print_msg "Linking package: ${pkg}"
        run_stow "$pkg" -R "${DRY_RUN}" "${FORCE}"
    done
}

# Core unsymlink work used by both 'unlink' and 'remove'
_do_unlink() {
    resolve_profiles PROFILES_INPUT INSTALL_PROFILES

    for profile in "${INSTALL_PROFILES[@]}"; do
        print_msg "Unlinking profile: ${profile}"
        unlink_pkglist "${PROFILE_DIR}/${profile}/stow.pkglist" "${DRY_RUN}" "${FORCE}"
    done

    for pkg in "${STOW_PKGS[@]}"; do
        print_msg "Unlinking package: ${pkg}"
        run_stow "$pkg" -D "${DRY_RUN}" "${FORCE}"
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

cmd_setup(){
   print_msg ""
   for setup in "${SETUPS_INPUT[@]}"; do
       print_msg "Executing setup routines for: ${setup}"
       run_setup "${SETUP_DIR}/${setup}/setup.sh"
   done
}

cmd_install() {
    # install implies link — symlinks are always set up first
    _do_link

    print_msg ""
    print_msg "Updating package repositories..."
    [[ "$DRY_RUN" -eq 0 ]] && sudo apt update

    for profile in "${INSTALL_PROFILES[@]}"; do
        print_msg "Installing apt packages for: ${profile}"
        apt_install_pkglist "${PROFILE_DIR}/${profile}/debian.pkglist"
    done

    # Individual -pkg targets have no pkglist — no apt action taken
    finish_msg
}

cmd_remove() {
    # Unlink first, then offer apt removal
    _do_unlink

    for profile in "${INSTALL_PROFILES[@]}"; do
        apt_remove_pkglist "${PROFILE_DIR}/${profile}/debian.pkglist"
    done

    # Individual -pkg targets have no pkglist — no apt action taken
}

cmd_list() {
    local sub="$1"

    case "$sub" in
	setups)
	    print_always "Available setups:"
	    printf "  %s\n" "${ALL_SETUPS[@]}"
	    ;;
        profiles)
            print_always "Available profiles:"
            printf "  %s\n" "${ALL_PROFILES[@]}"
            ;;
        packages)
            resolve_profiles PROFILES_INPUT INSTALL_PROFILES
            for profile in "${INSTALL_PROFILES[@]}"; do
                print_always "Profile '${profile}' stow packages:"
                list_file_contents "${PROFILE_DIR}/${profile}/stow.pkglist"
            done
            for pkg in "${STOW_PKGS[@]}"; do
                print_always "Package '${pkg}':"
                if dir_exists "${STOW_DIR}/${pkg}"; then
                    ls "${STOW_DIR}/${pkg}"
                else
                    print_always "  (not found in repo)"
                fi
            done
            ;;
        binaries)
            resolve_profiles PROFILES_INPUT INSTALL_PROFILES
            for profile in "${INSTALL_PROFILES[@]}"; do
                print_always "Profile '${profile}' apt packages:"
                list_file_contents "${PROFILE_DIR}/${profile}/debian.pkglist"
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
        [[ "$DRY_RUN" -eq 1 ]] && print_always "[dry-run] rm ${link}" && continue
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
  setup     Apply a setup configuration
  remove    Remove stow symlinks + remove apt packages
  list      Query profiles, packages + setups
  doctor    Find and remove broken symlinks

Targets (repeatable, combinable):
  -p  PROFILE   Operate on a profile (resolves dependencies)
  -pkg PKG      Operate on a single stow package
  -s SETUP      Operate on a single setup

Options:
  -f    Force overwrite existing dotfiles (stow --adopt + git reset)
  -q    Quiet — suppress informational output
  -n    Dry run — print what would happen, do nothing
  -h    Show this help
  --fix Fix broken symlinnks

List usage:
  $(basename "$0") list profiles
  $(basename "$0") list setups
  $(basename "$0") list packages  -p PROFILE [-p PROFILE ...]
  $(basename "$0") list packages  -pkg PKG   [-pkg PKG ...]
  $(basename "$0") list binaries  -p PROFILE [-p PROFILE ...]

Examples:
  $(basename "$0") install -p term
  $(basename "$0") install -p base -p dev-tools
  $(basename "$0") link    -pkg ranger -pkg tmux
  $(basename "$0") unlink  -p term-x11
  $(basename "$0") remove  -p dev-tools
  $(basename "$0") setup   -s syncthing
  $(basename "$0") list    profiles
  $(basename "$0") list    packages -p base
  $(basename "$0") list    binaries -p term
  $(basename "$0") install -p term -n
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

if ! dir_exists "$HOME/.local/bin"; then
   mkdir -p "$HOME/.local/bin"
fi

SUBCOMMAND="$1"
shift

# For 'list', consume the sub-action before general flag parsing
LIST_SUB=""
if [[ "$SUBCOMMAND" == "list" && "${1:-}" != -* && -n "${1:-}" ]]; then
    LIST_SUB="$1"
    shift
fi

# Parse flags and targets
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p)
            [[ -z "${2:-}" ]] && { print_always "Error: -p requires an argument."; exit 1; }
            PROFILES_INPUT+=("$2")
            shift 2
            ;;
        -s)
	    [[ -z "${2:-}" ]] && { print_always "Error: -s requires an argument."; exit 1; }
            SETUPS_INPUT+=("$2")
            shift 2
 	    ;;
        -pkg)
            [[ -z "${2:-}" ]] && { print_always "Error: -pkg requires an argument."; exit 1; }
            STOW_PKGS+=("$2")
            shift 2
            ;;
        -f) FORCE=1;   shift ;;
        -q) QUIET=1;   shift ;;
        -n) DRY_RUN=1; shift ;;
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
for profile in "${PROFILES_INPUT[@]}"; do
    if ! profile_exists "$profile"; then
        print_always "Error: profile '${profile}' does not exist."
        exit 1
    fi
done

# Validate all stow packages exist before doing any work
for pkg in "${STOW_PKGS[@]}"; do
    if ! stow_pkg_exists "$pkg"; then
        print_always "Error: stow package '${pkg}' does not exist."
        exit 1
    fi
done

# Validate all setups exist before doing any work
for setup in "${SETUPS_INPUT[@]}"; do
    if ! setup_exists "$setup"; then
        print_always "Error: setup '${setup}' does not exist."
	exit 1
    fi
done

# Require at least one target for action subcommands
case "$SUBCOMMAND" in
    link|unlink)
         if [[  ${#STOW_PKGS[@]} -eq 0  ]]; then
	     print_always "Error: '${SUBCOMMAND}' requires at least one -pkg target."
             print_always ""
             usage
             exit 1
         fi
         ;;
    install|remove)
         if [[ ${#PROFILES_INPUT[@]} -eq 0 ]]; then
             print_always "Error: '${SUBCOMMAND}' requires at least one -p target."
             print_always ""
             usage
             exit 1
         fi
         ;;
    setup)
         if [[ ${#SETUPS_INPUT[@]} -eq 0 ]]; then
             print_always "Error: '${SUBCOMMAND}' requires at least one -s target."
             print_always ""
             usage
             exit 1
         fi
         ;;
esac

# Dispatch
case "$SUBCOMMAND" in
    link)    cmd_link ;;
    unlink)  cmd_unlink ;;
    install) cmd_install ;;
    setup)   cmd_setup ;;
    remove)  cmd_remove ;;
    list)    cmd_list "$LIST_SUB" ;;
    doctor)  cmd_doctor ;;
    -h|--help) usage; exit 0 ;;
    *)
        print_always "Error: unknown subcommand '${SUBCOMMAND}'."
        print_always ""
        usage
        exit 1
        ;;
esac
