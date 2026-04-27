#!/usr/bin/env bash

mapfile -t ALL_PROFILES < <(ls "${PROFILE_DIR}")

# ===================================================================
# Profile helpers
# ===================================================================

profile_exists() { dir_exists "${PROFILE_DIR}/${1}"; }

# Recursively resolve profile deps into INSTALL_PROFILES (deps first)
register_profile_deps() {
    local deps_file="${PROFILE_DIR}/${1}/profile.deps"
    file_exists "${deps_file}" || return 0
    while IFS= read -r dep; do
        local already=0
        for p in "${INSTALL_PROFILES[@]}"; do
            [[ "$p" == "$dep" ]] && already=1 && break
        done
        if [[ $already -eq 0 ]]; then
            INSTALL_PROFILES+=("$dep")
            register_profile_deps "$dep"
        fi
    done < "${deps_file}"
}

# Expand PROFILES_INPUT into INSTALL_PROFILES with dep resolution
resolve_profiles() {
    for profile in "${PROFILES_INPUT[@]}"; do
        register_profile_deps "$profile"
        # Append the profile itself after its deps
        local already=0
        for p in "${INSTALL_PROFILES[@]}"; do
            [[ "$p" == "$profile" ]] && already=1 && break
        done
        [[ $already -eq 0 ]] && INSTALL_PROFILES+=("$profile")
    done
}


