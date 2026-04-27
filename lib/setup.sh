
#!/usr/bin/env bash

mapfile -t ALL_SETUPS < <(ls "${SETUP_DIR}")

# ============================================================
# Setup helpers
# ============================================================
setup_exists() { dir_exists "${SETUP_DIR}/${1}"; }

run_setup() {
    local setup_script="$1"
    file_exists "$setup_script" || return 0
    if [[ "$DRY_RUN" -eq 1 ]]; then
        print_always "[dry-run] bash ${setup_script}"
    else
        bash "$setup_script"
    fi
}

