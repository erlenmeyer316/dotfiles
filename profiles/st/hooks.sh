#!/usr/bin/env bash

ST_BUILD_DIR="/tmp/dotfiles/build/st"
ST_GIT_REPO="https://github.com/erlenmeyer316/st"


_checkout_repo(){
  local repo="${1}"
  local dir="${2}"
  
  mkdir -p $dir

  git -C $dir clone $repo .
  ls $dir
}

_build_src(){
   local src="${1}"
   make -C ${src}
}

_install_from_src(){
   local src="${1}"
   sudo make -C ${src} install
}

_clean_up(){
   local src="${1}"
   rm -rf $src 
}

_install_st(){
   _checkout_repo ${ST_GIT_REPO} ${ST_BUILD_DIR}
   _build_src ${ST_BUILD_DIR}
   _install_from_src ${ST_BUILD_DIR}
   _clean_up ${ST_BUILD_DIR}
}


dotfiles_hook_install() {
    _install_st
}

