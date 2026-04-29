#!/usr/bin/env bash


# ===================================================================
# Profile helpers
# ===================================================================

profile_exists() { 
    local profile_dir="${1}" profile="${2}"
    dir_exists "${profile_dir}/${profile}";
}

# Recursively resolve profile deps into INSTALL_PROFILES (deps first)
register_profile_deps() {
    local profile_dir="${1}" profile="${2}"
    local deps_file="${profile_dir}/${profile}/profile.deps"
    local -n rpd_install_profiles=$3
    file_exists "${deps_file}" || return 0
    while IFS= read -r dep; do
        local already=0
        for p in "${rpd_install_profiles[@]}"; do
            [[ "$p" == "$dep" ]] && already=1 && break
        done
        if [[ $already -eq 0 ]]; then
            rpd_install_profiles+=("$dep")
            register_profile_deps "${profile_dir}" "$dep" $3
        fi
    done < "${deps_file}"
}

# Expand PROFILES_INPUT into INSTALL_PROFILES with dep resolution
resolve_profiles() {
    local profile_dir="${1}"
    local -n rp_profiles_input=$2
    local -n rp_install_profiles=$3

    for profile in "${rp_profiles_input[@]}"; do
        register_profile_deps "${profile_dir}" "$profile" $3
        # Append the profile itself after its deps
        local already=0
        for p in "${rp_install_profiles[@]}"; do
            [[ "$p" == "$profile" ]] && already=1 && break
        done
        [[ $already -eq 0 ]] && rp_install_profiles+=("$profile")
    done
}


