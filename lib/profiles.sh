#!/usr/bin/env bash

mapfile -t ALL_PROFILES < <(ls "${PROFILE_DIR}")

# ===================================================================
# Profile helpers
# ===================================================================

profile_exists() { dir_exists "${PROFILE_DIR}/${1}"; }

# Recursively resolve profile deps into INSTALL_PROFILES (deps first)
register_profile_deps() {
    local deps_file="${PROFILE_DIR}/${1}/profile.deps"
    local -n rpd_install_profiles=$2
    file_exists "${deps_file}" || return 0
    while IFS= read -r dep; do
        local already=0
        for p in "${rpd_install_profiles[@]}"; do
            [[ "$p" == "$dep" ]] && already=1 && break
        done
        if [[ $already -eq 0 ]]; then
            rpd_install_profiles+=("$dep")
            register_profile_deps "$dep" $2
        fi
    done < "${deps_file}"
}

# Expand PROFILES_INPUT into INSTALL_PROFILES with dep resolution
resolve_profiles() {
    local -n rp_profiles_input=$1
    local -n rp_install_profiles=$2
    for profile in "${rp_profiles_input[@]}"; do
        register_profile_deps "$profile" $2
        # Append the profile itself after its deps
        local already=0
        for p in "${rp_install_profiles[@]}"; do
            [[ "$p" == "$profile" ]] && already=1 && break
        done
        [[ $already -eq 0 ]] && rp_install_profiles+=("$profile")
    done
}


