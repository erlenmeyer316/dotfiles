#!/usr/bin/env bash

shopt -s nullglob

HELP=0
QUIET=0
INSTALL_BINARIES=0
LIST_BINARIES=0
LIST_PACKAGES=0
PROFILE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROFILES=$(ls "${SCRIPT_DIR}/profiles")
FORCE=0

profile_exists() {
  if [ -d "${SCRIPT_DIR}/profiles/${1}" ]; then
     return 0
  fi
  return 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

package_installed() {
   if dpkg -s "$1" &> /dev/null; then
      return 0
   fi
   return 1
}


print_msg() {
  printf "%s\n" "$1"
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
      print_msg "${PROFILES[@]}"
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
   
   STOW_PKGS="${SCRIPT_DIR}/profiles/${PROFILE}/stow.packages"
   BINARIES="${SCRIPT_DIR}/profiles/${PROFILE}/debian.packages"

   if [ "$LIST_PACKAGES" -eq "1" ]; then
       print_msg "$PROFILE includes the following configuration:"
       cat -n "${STOW_PKGS}"
       exit 0
   fi

   if [ "$LIST_BINARIES" -eq "1" ]; then
       print_msg "$PROFILE includes the following binaries:"
       cat -n "${BINARIES}"
       exit 0
   fi
   
   for stow_pkg in $(cat "$STOW_PKGS")
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


   if [ "$INSTALL_BINARIES" -eq "1" ]; then
     if [ "$QUIET" -eq "0" ]; then
        print_msg "Updating package repositories..."
     fi	
     sudo apt update
     for binary in $(cat "$BINARIES")
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

   if command_exists "git"; then
     if [ "$FORCE" -eq "1" ]; then
        git -c "${SCRIPT_DIR}" reset --hard
     fi
   fi
fi



