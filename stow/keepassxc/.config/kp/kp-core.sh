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

# Kernel keyring key name — derived from service/account for uniqueness
_KP_KERNEL_KEY="${KP_KEYRING_SERVICE}:${KP_KEYRING_ACCOUNT}"

# ── Debug mode ────────────────────────────────────────────────────────────────
# Enable with KP_DEBUG=1 or by running: kp debug <command> [entry]
# Strips 2>/dev/null so keepassxc-cli speaks freely.
# Also prints the resolved config and exact command being run.

_kp_debug_info() {
    # Check each keyring backend independently to avoid stdout concatenation
    local kernel_cached=no secret_cached=no
    if command -v keyctl >/dev/null 2>&1; then
        local keyid
        keyid=$(keyctl search @s user "$_KP_KERNEL_KEY" 2>/dev/null) \
            && kernel_cached=yes
    fi
    if command -v secret-tool >/dev/null 2>&1; then
        local val
        val=$(secret-tool lookup \
            "$KP_KEYRING_SERVICE" "$KP_KEYRING_ACCOUNT" 2>/dev/null) \
            && [[ -n "$val" ]] && secret_cached=yes
    fi

    echo "── kp debug ─────────────────────────────────" >&2
    echo "  KP_DB              = ${KP_DB}" >&2
    echo "  DB exists          = $([[ -f "$KP_DB" ]] && echo yes || echo 'NO — FILE NOT FOUND')" >&2
    echo "  DB readable        = $([[ -r "$KP_DB" ]] && echo yes || echo 'NO — PERMISSION DENIED')" >&2
    echo "  keepassxc-cli      = $(command -v keepassxc-cli 2>/dev/null || echo NOT FOUND)" >&2
    echo "  keepassxc-cli ver  = $(keepassxc-cli --version 2>&1 || echo unknown)" >&2
    echo "  keyctl             = $(command -v keyctl 2>/dev/null || echo 'not found — install keyutils')" >&2
    echo "  secret-tool        = $(command -v secret-tool 2>/dev/null || echo not found)" >&2
    echo "  KP_PASS set        = $([[ -n "${KP_PASS:-}" ]] && echo yes || echo no)" >&2
    echo "  Kernel keyring     = ${kernel_cached}" >&2
    echo "  GNOME keyring      = ${secret_cached}" >&2
    echo "─────────────────────────────────────────────" >&2
}

# ── Dependency check ──────────────────────────────────────────────────────────
_kp_require() {
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "kp: required command not found: ${cmd}" >&2
            return 1
        fi
    done
}

# ── Kernel keyring helpers ────────────────────────────────────────────────────
# Uses the Linux kernel session keyring (@s) — no daemon required, works on
# TTY and X11 equally. Session keyring is automatically cleared on logout.
# Requires: keyutils (apt install keyutils)

_kp_kernel_get() {
    command -v keyctl >/dev/null 2>&1 || return 1
    local keyid
    keyid=$(keyctl search @s user "$_KP_KERNEL_KEY" 2>/dev/null) || return 1
    keyctl print "$keyid" 2>/dev/null
}

_kp_kernel_set() {
    command -v keyctl >/dev/null 2>&1 || return 1
    keyctl add user "$_KP_KERNEL_KEY" "$1" @s >/dev/null 2>&1
}

_kp_kernel_clear() {
    command -v keyctl >/dev/null 2>&1 || return 1
    keyctl purge user "$_KP_KERNEL_KEY" >/dev/null 2>&1 || true
}

# ── Secret-tool helpers ───────────────────────────────────────────────────────
# libsecret / GNOME keyring — works on X11 sessions with the daemon running.
# Falls back silently on TTY-only systems where the daemon is absent.

_kp_secret_get() {
    command -v secret-tool >/dev/null 2>&1 || return 1
    local val
    val=$(secret-tool lookup \
        "$KP_KEYRING_SERVICE" "$KP_KEYRING_ACCOUNT" 2>/dev/null) || return 1
    [[ -n "$val" ]] && echo "$val"
}

_kp_secret_set() {
    command -v secret-tool >/dev/null 2>&1 || return 1
    echo -n "$1" | secret-tool store \
        --label="kp master password" \
        "$KP_KEYRING_SERVICE" "$KP_KEYRING_ACCOUNT" 2>/dev/null
}

_kp_secret_clear() {
    command -v secret-tool >/dev/null 2>&1 || return 1
    secret-tool clear \
        "$KP_KEYRING_SERVICE" "$KP_KEYRING_ACCOUNT" 2>/dev/null || true
}

# ── Master password supply ────────────────────────────────────────────────────
# Resolution order:
#   1. KP_PASS env var       — explicit override, never cached, for scripts
#   2. Kernel keyring        — TTY-native, session-scoped, no daemon needed
#   3. secret-tool           — X11/GNOME keyring fallback
#   4. Interactive prompt    — cache offer on successful entry
#
# Password emitted on stdout. All user-facing messages go to stderr
# so stdout stays clean for piping into keepassxc-cli.

_kp_get_master() {
    # 1. Explicit env var
    if [[ -n "${KP_PASS:-}" ]]; then
        echo "$KP_PASS"
        return 0
    fi

    # 2. Kernel keyring
    local cached
    cached=$(_kp_kernel_get 2>/dev/null) && [[ -n "$cached" ]] && {
        echo "$cached"
        return 0
    }

    # 3. secret-tool (X11 sessions)
    cached=$(_kp_secret_get 2>/dev/null) && [[ -n "$cached" ]] && {
        echo "$cached"
        return 0
    }

    # 4. Interactive prompt — requires a tty
    if [[ ! -t 0 ]] && [[ ! -e /dev/tty ]]; then
        echo "kp: no master password available and no tty for prompt" >&2
        echo "kp: run 'kp unlock' in your session first, or set KP_PASS" >&2
        return 1
    fi

    local pw
    read -rsp "KeePass master password: " pw </dev/tty
    echo >&2   # newline after silent read

    if [[ -z "$pw" ]]; then
        echo "kp: no password entered" >&2
        return 1
    fi

    # Offer to cache — prefer kernel keyring, fall back to secret-tool
    local store
    read -rp "Cache in keyring for this session? [y/N] " store </dev/tty
    if [[ "$store" =~ ^[Yy]$ ]]; then
        if command -v keyctl >/dev/null 2>&1; then
            _kp_kernel_set "$pw" \
                && echo "kp: cached in kernel keyring. Run 'kp lock' to evict." >&2 \
                || echo "kp: kernel keyring cache failed." >&2
        elif command -v secret-tool >/dev/null 2>&1; then
            _kp_secret_set "$pw" \
                && echo "kp: cached in GNOME keyring. Run 'kp lock' to evict." >&2 \
                || echo "kp: GNOME keyring cache failed — is the daemon running?" >&2
        else
            echo "kp: no keyring backend available (install keyutils for kernel keyring)." >&2
        fi
    fi

    echo "$pw"
}

# ── keepassxc-cli runner ──────────────────────────────────────────────────────
# Pipes master password into keepassxc-cli via stdin.
# stderr suppressed to silence the password prompt on non-debug runs.
# Note: -q intentionally omitted — in 2.7.x it suppresses stdin reads.
#
# Usage: _kp_cli <subcommand> [subcommand-options] <db> [entry]

_kp_cli() {
    _kp_require keepassxc-cli || return 1
    local pw
    pw=$(_kp_get_master) || return 1

    if [[ -n "${KP_DEBUG:-}" ]]; then
        echo "  _kp_cli args       = $*" >&2
        echo "  password length    = ${#pw}" >&2
        echo "  running: keepassxc-cli $*" >&2
        echo "─────────────────────────────────────────────" >&2
        # Run without stderr suppression so we see everything
        echo "$pw" | keepassxc-cli "$@"
    else
        echo "$pw" | keepassxc-cli "$@" 2>/dev/null
    fi
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