# kp-core.sh — shared library for kp tooling
# Source this file; do not execute it directly.
# Provides: config resolution, master password supply, _kp_cli(), _kp_clip()
# Tested against keepassxc-cli 2.7.x

# Guard against double-sourcing
[[ -n "${_KP_CORE_LOADED:-}" ]] && return 0
_KP_CORE_LOADED=1

# ── Config resolution ─────────────────────────────────────────────────────────
# Resolution order (lowest → highest priority):
#   1. Hardcoded fallbacks below
#   2. ~/.config/kp/config — stowed from dotfiles
#   3. Env vars — win over everything, safe for scripted/one-shot use

_KP_CONFIG="${XDG_CONFIG_HOME:-${HOME}/.config}/kp/config"
[[ -f "$_KP_CONFIG" ]] && source "$_KP_CONFIG"

KP_DB="${KP_DB:-${HOME}/Sync/keepassxc/Passwords.kdbx}"
KP_CLIP_TIMEOUT="${KP_CLIP_TIMEOUT:-10}"
KP_KEYRING_SERVICE="${KP_KEYRING_SERVICE:-kp}"
KP_KEYRING_ACCOUNT="${KP_KEYRING_ACCOUNT:-master}"

# ── Dependency check ──────────────────────────────────────────────────────────
_kp_require() {
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "kp: required command not found: ${cmd}" >&2
            return 1
        fi
    done
}

# ── Master password supply ────────────────────────────────────────────────────
# Resolution order:
#   1. KP_PASS env var  — explicit override, never cached, for scripted use
#   2. System keyring   — session-cached after first interactive unlock
#   3. Interactive prompt — with offer to cache in keyring
#
# Password emitted on stdout. All user-facing messages go to stderr
# so stdout stays clean for piping into keepassxc-cli.

_kp_get_master() {
    # 1. Explicit env var
    if [[ -n "${KP_PASS:-}" ]]; then
        echo "$KP_PASS"
        return 0
    fi

    # 2. System keyring
    if command -v secret-tool >/dev/null 2>&1; then
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
        echo "kp: run 'kp unlock' in your session first, or set KP_PASS" >&2
        return 1
    fi

    local pw
    read -rsp "KeePass master password: " pw </dev/tty
    echo >&2   # newline after silent read

    if command -v secret-tool >/dev/null 2>&1; then
        local store
        read -rp "Cache in keyring for this session? [y/N] " store </dev/tty
        if [[ "$store" =~ ^[Yy]$ ]]; then
            echo -n "$pw" | secret-tool store \
                --label="kp master password" \
                "$KP_KEYRING_SERVICE" "$KP_KEYRING_ACCOUNT" 2>/dev/null
            echo "kp: cached in keyring. Run 'kp lock' to evict." >&2
        fi
    fi

    echo "$pw"
}

# ── keepassxc-cli runner ──────────────────────────────────────────────────────
# Pipes master password into keepassxc-cli.
#
# -q (--quiet) is a global flag that silences the password prompt and
# secondary output. It MUST precede the subcommand — placing it after
# positional args is silently ignored (was the original bug).
#
# Usage: _kp_cli <subcommand> [subcommand-options] <db> [entry]

_kp_cli() {
    _kp_require keepassxc-cli || return 1
    local pw
    pw=$(_kp_get_master) || return 1
    echo "$pw" | keepassxc-cli -q "$@" 2>/dev/null
}

# ── Clipboard helper ──────────────────────────────────────────────────────────
# Copies a value to clipboard and schedules a background auto-clear.
# Falls back: xclip → xsel → wl-copy (wayland future-proofing)

_kp_clip() {
    local value="$1"
    local copied=0

    if command -v xclip >/dev/null 2>&1; then
        echo -n "$value" | xclip -selection clipboard && copied=1
    elif command -v xsel >/dev/null 2>&1; then
        echo -n "$value" | xsel --clipboard --input && copied=1
    elif command -v wl-copy >/dev/null 2>&1; then
        echo -n "$value" | wl-copy && copied=1
    fi

    if [[ $copied -eq 0 ]]; then
        echo "kp: no clipboard tool found (xclip, xsel, or wl-copy required)" >&2
        return 1
    fi

    echo "kp: copied to clipboard. Clearing in ${KP_CLIP_TIMEOUT}s..." >&2

    local timeout="$KP_CLIP_TIMEOUT"
    (
        sleep "$timeout"
        if command -v xclip >/dev/null 2>&1; then
            echo -n "" | xclip -selection clipboard
        elif command -v xsel >/dev/null 2>&1; then
            echo -n "" | xsel --clipboard --input
        elif command -v wl-copy >/dev/null 2>&1; then
            wl-copy --clear
        fi
    ) &
    disown
}

# ── Entry picker ──────────────────────────────────────────────────────────────
# Interactive fzf picker over vault entries. Prints selected entry path.
#
# ls -R = recursive, -f = flatten to Group/Subgroup/Entry paths (one per line)
# Flattened output contains no group-only lines so no filtering needed.

_kp_pick() {
    _kp_require fzf || return 1
    _kp_cli ls -R -f "$KP_DB" \
        | fzf --prompt="  entry: " \
              --height=40% \
              --layout=reverse \
              --no-multi
}

# ── Field extractors ──────────────────────────────────────────────────────────
# Primitives used by both kp and any sourcing scripts (e.g. qutebrowser userscripts).
#
# keepassxc-cli 2.7.x `show` output format:
#   Title: <value>
#   UserName: <value>
#   Password: <value>      (requires -s / --show-protected)
#   URL: <value>
#   Notes: <value>
#   TOTP: <value>          (requires -t / --totp)

_kp_field_password() {
    _kp_cli show -s "$KP_DB" "$1" \
        | grep -i "^Password:" | cut -d' ' -f2-
}

_kp_field_username() {
    _kp_cli show "$KP_DB" "$1" \
        | grep -i "^UserName:" | cut -d' ' -f2-
}

_kp_field_totp() {
    # -t adds TOTP to show output; errors if no TOTP configured for entry
    _kp_cli show -t "$KP_DB" "$1" \
        | grep -i "^TOTP:" | cut -d' ' -f2-
}

_kp_field_url() {
    _kp_cli show "$KP_DB" "$1" \
        | grep -i "^URL:" | cut -d' ' -f2-
}