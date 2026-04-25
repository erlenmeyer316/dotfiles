# kp-core.sh — shared library for kp tooling
# Source this file; do not execute it directly.
# Provides: config resolution, master password supply, _kp_cli(), _kp_clip()

# Guard against double-sourcing
[[ -n "${_KP_CORE_LOADED:-}" ]] && return 0
_KP_CORE_LOADED=1

# ── Config resolution ─────────────────────────────────────────────────────────
# Load config file, then env vars override. This order means:
#   1. Hardcoded defaults (below) are the last resort
#   2. Config file overrides defaults
#   3. Env vars override everything — safe for scripted/one-shot use

_KP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/kp/config"
[[ -f "$_KP_CONFIG" ]] && source "$_KP_CONFIG"

KP_DB="${KP_DB:-$HOME/Sync/keepassxc/Passwords.kdbx}"
KP_CLIP_TIMEOUT="${KP_CLIP_TIMEOUT:-10}"
KP_KEYRING_SERVICE="${KP_KEYRING_SERVICE:-kp}"
KP_KEYRING_ACCOUNT="${KP_KEYRING_ACCOUNT:-master}"

# ── Dependency checks ─────────────────────────────────────────────────────────
_kp_require() {
    # Usage: _kp_require cmd [cmd...]
    # Exits with a clear error if any required command is missing
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "kp: required command not found: $cmd" >&2
            return 1
        fi
    done
}

# ── Master password supply ────────────────────────────────────────────────────
# Resolution order:
#   1. KP_PASS env var     — explicit override, never cached
#   2. System keyring      — session-cached after first unlock
#   3. Interactive prompt  — with offer to cache in keyring
#
# Callers receive the password on stdout.
# All user-facing messages go to stderr so stdout stays clean for piping.

_kp_get_master() {
    # 1. Explicit env var — useful in non-interactive scripts
    if [[ -n "${KP_PASS:-}" ]]; then
        echo "$KP_PASS"
        return 0
    fi

    # 2. Try the system keyring
    if command -v secret-tool &>/dev/null; then
        local cached
        cached=$(secret-tool lookup \
            "$KP_KEYRING_SERVICE" "$KP_KEYRING_ACCOUNT" 2>/dev/null || true)
        if [[ -n "$cached" ]]; then
            echo "$cached"
            return 0
        fi
    fi

    # 3. Interactive prompt — requires a tty
    if [[ ! -t 0 ]] && [[ ! -e /dev/tty ]]; then
        echo "kp: no master password available and no tty for prompt" >&2
        return 1
    fi

    local pw
    read -rsp "KeePass master password: " pw </dev/tty
    echo >&2   # newline after silent read

    # Offer to cache — only if secret-tool is available
    if command -v secret-tool &>/dev/null; then
        local store
        read -rp "Cache in keyring for this session? [y/N] " store </dev/tty
        if [[ "$store" =~ ^[Yy]$ ]]; then
            echo -n "$pw" | secret-tool store \
                --label="kp master password" \
                "$KP_KEYRING_SERVICE" "$KP_KEYRING_ACCOUNT" 2>/dev/null
            echo "kp: cached in keyring. Run 'kp lock' to clear." >&2
        fi
    fi

    echo "$pw"
}

# ── keepassxc-cli runner ──────────────────────────────────────────────────────
# Pipes master password into keepassxc-cli, suppressing its password prompt.
# Usage: _kp_cli <keepassxc-cli args...>

_kp_cli() {
    _kp_require keepassxc-cli || return 1
    local pw
    pw=$(_kp_get_master) || return 1
    echo "$pw" | keepassxc-cli "$@" --no-password-prompt 2>/dev/null
}

# ── Clipboard helper ──────────────────────────────────────────────────────────
# Copies a value to clipboard and schedules a background clear.
# Falls back gracefully: xclip → xsel → wl-copy (wayland future-proofing)

_kp_clip() {
    local value="$1"
    local copied=0

    if command -v xclip &>/dev/null; then
        echo -n "$value" | xclip -selection clipboard
        copied=1
    elif command -v xsel &>/dev/null; then
        echo -n "$value" | xsel --clipboard --input
        copied=1
    elif command -v wl-copy &>/dev/null; then
        echo -n "$value" | wl-copy
        copied=1
    fi

    if [[ $copied -eq 0 ]]; then
        echo "kp: no clipboard tool found (xclip, xsel, or wl-copy required)" >&2
        return 1
    fi

    echo "kp: copied to clipboard. Clearing in ${KP_CLIP_TIMEOUT}s..." >&2

    # Clear in background — subprocess inherits the timeout value
    local timeout="$KP_CLIP_TIMEOUT"
    (
        sleep "$timeout"
        if command -v xclip &>/dev/null; then
            echo -n "" | xclip -selection clipboard
        elif command -v xsel &>/dev/null; then
            echo -n "" | xsel --clipboard --input
        elif command -v wl-copy &>/dev/null; then
            wl-copy --clear
        fi
    ) &
    disown   # detach so it survives shell exit
}

# ── Entry picker ──────────────────────────────────────────────────────────────
# Interactive fzf picker over vault entries. Prints selected entry path.

_kp_pick() {
    _kp_require fzf || return 1
    _kp_cli ls --recursive "$KP_DB" \
        | grep -v '/$' \
        | fzf --prompt="  entry: " \
              --height=40% \
              --layout=reverse \
              --no-multi
}

# ── Field extractors ──────────────────────────────────────────────────────────
# Each takes an entry path, returns the field value on stdout.
# These are the primitives — kp and userscripts both build on these.

_kp_field_password() {
    _kp_cli show --show-protected "$KP_DB" "$1" \
        | grep -i "^Password:" | cut -d' ' -f2-
}

_kp_field_username() {
    _kp_cli show "$KP_DB" "$1" \
        | grep -i "^UserName:" | cut -d' ' -f2-
}

_kp_field_totp() {
    _kp_cli show --totp "$KP_DB" "$1" \
        | grep -i "^TOTP:" | cut -d' ' -f2-
}

_kp_field_url() {
    _kp_cli show "$KP_DB" "$1" \
        | grep -i "^URL:" | cut -d' ' -f2-
}
