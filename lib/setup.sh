
#!/usr/bin/env bash


# ============================================================
# Setup helpers
# ============================================================
setup_exists() { 
    local setup_dir="${1}" setup="$2"
    dir_exists "${setup_dir}/${setup}";
}

run_setup() {
    local setup_script="$1"
    file_exists "$setup_script" || return 0
    if [[ "$DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] bash ${setup_script}"
    else
        bash "$setup_script"
    fi
}

