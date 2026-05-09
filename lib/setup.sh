
#!/usr/bin/env bash


# ============================================================
# Setup helpers
# ============================================================
setup_exists() { 
    local setup_dir="${1}" setup="${2}"
    dir_exists "${setup_dir}/${setup}";
}


execute_pre_link_setups() {
   local setupdir="${1}" setuplist="${2}"
   echo "$setuplist"
   file_exists "$setuplist" || return 0

   while IFS=: read -r setup; do
       execute_setup "${setupdir}/${setup}/pre-link.sh"
   done < "$setuplist"
}

execute_pre_install_setups(){
   local setupdir="${1}" setuplist="${2}"

   echo "$setuplist"
   file_exists "$setuplist" || return 0

   while IFS=: read -r setup; do
       execute_setup "${setupdir}/${setup}/pre-install.sh"
   done < "$setuplist"
}

execute_post_install_setups() {
   local setupdir="${1}" setuplist="${2}"

   echo "$setuplist"
   file_exists "$setuplist" || return 0

   while IFS=: read -r setup; do
   execute_setup "${setupdir}/${setup}/post-install.sh"
   done < "$setuplist"
}

execute_setup() {
    local setup_script="${1}"
    echo "$setup_script"
    file_exists "$setup_script" || return 0
    if [[ "$DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] bash ${setup_script}"
    else
        bash "$setup_script"
    fi
}

