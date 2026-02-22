#!/usr/bin/env bash

shopt -s nullglob

# utility functions
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

package_installed() {
   if dpkg -s "$1" &> /dev/null; then
      return 0
   fi
   return 1
}

file_exists() {
   if [ -f "$1" ]; then
      return 0
   fi
   return 1
}

list_file_contents() {
    if file_exists "$1"; then
         cat -n "${1}"
    fi
}

print_msg() {
  printf "%s\n" "$1"
}

# script variables
PROFILE=""
INSTALL_PROFILE=()
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROFILES=$(ls "${SCRIPT_DIR}/profiles")

# script flags
FORCE=0
INSTALL_BINARIES=0
HELP=0
LIST_BINARIES=0
LIST_PACKAGES=0
QUIET=0

# script functions
profile_exists() {
  if [ -d "${SCRIPT_DIR}/profiles/${1}" ]; then
     return 0
  fi
  return 1
}

link_stow_packages() {
   if file_exists $1; then
      for stow_pkg in $(cat "$1")
      do
        if [ "$QUIET" -eq "0" ]; then
          print_msg "Linking $stow_pkg configuration"
        fi
        if [ "$FORCE" -eq "1" ]; then
            stow --adopt -d "${SCRIPT_DIR}" -t ~ -S $stow_pkg
        else
            stow -d "${SCRIPT_DIR}" -t ~ -S $stow_pkg
        fi
      done
   fi
}

install_binaries() {
   if file_exists "$1"; then
     for binary in $(cat "$1")
      do
        if ! package_installed "$binary"; then
          if [ "$QUIET" -eq "0" ]; then
            print_msg "Installing $binary.."
          fi	
          sudo apt-get install -y $binary
       else
          if [ "$QUIET" -eq "0" ]; then
            print_msg "$binary is already installed"
          fi	
        fi
      done
   fi
 }

register_profile_deps() {
   DEPS_FILE="${SCRIPT_DIR}/profiles/${1}/profile.deps"
   if file_exists "${DEPS_FILE}"; then
      for dep in $(cat "${DEPS_FILE}")
      do
         add=1
	 for profile in "${INSTALL_PROFILES[@]}"
         do
	    if [ "$profile" == "$dep" ]; then
	       add=0
	    fi
	 done
	 if [ $add -eq 1 ]; then
	    INSTALL_PROFILES+=("${dep}")
	    register_profile_deps $dep
	 fi
      done
   fi
}


list_packages() {
    print_msg "$1 includes the following configuration:"
    list_file_contents "${SCRIPT_DIR}/profiles/${1}/stow.pkglist"
}

list_binaries(){
    print_msg "$1 includes the following binaries:"
    list_file_contents "${SCRIPT_DIR}/profiles/${1}/debian.pkglist"
}

install_profile() {
   INSTALL_PROFILES+=("${1}")
   register_profile_deps ${1}
  
   # link stow packages
   for i in "${INSTALL_PROFILES[@]}"
   do
      link_stow_packages "${SCRIPT_DIR}/profiles/${i}/stow.pkglist"
   done


   if [ "$INSTALL_BINARIES" -eq "1" ]; then
      if [ "$QUIET" -eq "0" ]; then
         print_msg "Updating package repositories..."
      fi	
      sudo apt update
      
      for i in "${INSTALL_PROFILES[@]}"
      do
        install_binaries "${SCRIPT_DIR}/profiles/${i}/debian.pkglist"
      done
   fi
   
   if command_exists "git"; then
     if [ "$FORCE" -eq "1" ]; then
        git -C "${SCRIPT_DIR}" reset --hard
     fi
   fi
   
   if file_exists "~/.profile"; then
      source ~/.profile
   fi
}

usage() {
   echo "Usage: $(basename "$0") -p [PROFILE] [-FLAG]" 
   echo ""
   echo " -h              Show help"
   echo " -i              Install binaries"
   echo " -b              List included profile binaries"
   echo " -s              List included stow packages"
   echo " -l              List profiles"
   echo " -f              Force overwrite existing files"
   echo " -q              Quiet"
}

if ! command_exists "stow"; then
   print_msg "Error: stow not installed."
   exit 1
fi

if [ "$#" -eq 0 ]; then
   print_msg "Error: Invalid arguments."
   usage
   exit 1
fi	

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in 
    -q)
       QUIET=1
       shift 
       ;;
    -h)
       usage
       exit 0
       ;;
    -p)
       PROFILE="$2"
       shift
       shift 
       ;;
    -i)
       INSTALL_BINARIES=1
       shift
       ;;
    -b)
       LIST_BINARIES=1
       shift
       ;;
    -s)
       LIST_PACKAGES=1
       shift
       ;;
    -f)
       FORCE=1
       shift
       ;;
    -l)
      print_msg "Available profiles:"
      echo "${PROFILES[@]}"
      exit 0
      ;;
    *)
      print_msg "Error: Unknown argument: $1."
      print_msg ""
      usage
      exit 1
      ;;
  esac
done


if [[ ! -z "$PROFILE" ]]; then
   
   if ! profile_exists "$PROFILE"; then
      print_msg "Error: Profile $PROFILE does not exist."
      exit 1
   fi
   
    if [ "$LIST_PACKAGES" -eq "1" ]; then
      list_packages "$PROFILE"
      exit 0
   fi

   if [ "$LIST_BINARIES" -eq "1" ]; then
      list_binaries "$PROFILE"
      exit 0
   fi

   install_profile "$PROFILE"
fi
