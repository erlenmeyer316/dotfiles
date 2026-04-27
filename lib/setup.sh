
#!/usr/bin/env bash

# ============================================================
# Setup helpers
# ============================================================
setup_exists() { dir_exists "${SCRIPT_DIR}/setup/${1}"; }

run_setup() {
    local setup_script="$1"
    echo "${setup_script}"
    file_exists "$setup_script" || return 0
    if [[ "$DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] bash ${setup_script}"
    else
        bash "$setup_script"
    fi
}

