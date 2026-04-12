# ~/.config/bash/functions.d/syncthing.bash

# ── Internal helpers ──────────────────────────────────────────────────────────

_st_config() {
  # Try XDG path first, fall back to legacy location
  local paths=(
    "$HOME/.local/state/syncthing/config.xml"
    "$HOME/.config/syncthing/config.xml"
  )
  for p in "${paths[@]}"; do
    [[ -f "$p" ]] && echo "$p" && return
  done
  echo "ERROR: syncthing config.xml not found" >&2
  return 1
}

_st_key() {
  local cfg; cfg=$(_st_config) || return 1
  grep -oP '(?<=<apikey>)[^<]+' "$cfg"
}

_st_curl() {
  # Wrapper: injects key, checks for empty response, returns raw JSON
  local key; key=$(_st_key) || return 1
  local result
  result=$(curl -sfk -H "X-API-Key: $key" "https://127.0.0.1:8384$1")
  local rc=$?
  if [[ $rc -ne 0 || -z "$result" ]]; then
    echo "ERROR: no response from Syncthing (is the daemon running?)" >&2
    echo "  curl exit code: $rc" >&2
    echo "  endpoint: $1" >&2
    return 1
  fi
  echo "$result"
}

# ── Public commands ───────────────────────────────────────────────────────────

st-key() {
   key=$(_st_key)
   echo "Device ID: ${key}"
}

# st — system overview
st() {
  echo "── System ───────────────────────────────────────"
  local sys; sys=$(_st_curl /rest/system/status) || return 1
  echo "$sys" | jq -r '"Device ID : " + .myID, "Version   : " + .version'

  echo ""
  echo "── Connections ──────────────────────────────────"
  local conn; conn=$(_st_curl /rest/system/connections) || return 1
  echo "$conn" | jq -r '
    .connections | to_entries[] |
    "\(.key[:8])…  connected=\(.value.connected)  \(.value.address)"
  '

  echo ""
  echo "── Folders ──────────────────────────────────────"
  local folders; folders=$(_st_curl /rest/config/folders) || return 1
  echo "$folders" | jq -r '.[] | "\(.id)  \(.label)  →  \(.path)"'
}

# st-status — per-folder sync state
st-status() {
  local folders; folders=$(_st_curl /rest/config/folders) || return 1
  local ids; ids=$(echo "$folders" | jq -r '.[].id')
  local key; key=$(_st_key)

  while IFS= read -r id; do
    local label path state
    label=$(echo "$folders" | jq -r --arg id "$id" '.[] | select(.id==$id) | .label')
    path=$(echo "$folders"  | jq -r --arg id "$id" '.[] | select(.id==$id) | .path')
    state=$(curl -sfk -H "X-API-Key: $key" \
      "https://127.0.0.1:8384/rest/db/status?folder=$id" \
      | jq -r '.state // "unknown"')
    printf "%-20s %-12s %s\n" "$label" "[$state]" "$path"
  done <<< "$ids"
}

# st-pending — show devices/folders waiting for acceptance
st-pending() {
  echo "── Pending Devices ──────────────────────────────"
  _st_curl /rest/config/pendingdevices \
    | jq -r 'to_entries[] | "\(.key[:8])…  last seen: \(.value.time[:19])"' \
    || return 1

  echo ""
  echo "── Pending Folders ──────────────────────────────"
  _st_curl /rest/config/pendingfolders \
    | jq -r 'to_entries[] | "\(.key)  offered by: \(.value.offeredBy | keys[])"' \
    || return 1
}

# st-watch — live event stream (Ctrl-C to stop)
st-watch() {
  local key; key=$(_st_key) || return 1
  local since=0
  echo "Watching Syncthing events (Ctrl-C to stop)…"
  while true; do
    local events
    events=$(curl -sfk -H "X-API-Key: $key" \
      "https://127.0.0.1:8384/rest/events?since=${since}&timeout=30")
    [[ -z "$events" || "$events" == "[]" ]] && continue
    since=$(echo "$events" | jq -r '.[-1].id')
    echo "$events" | jq -r '.[] | "\(.time[:19])  \(.type)  \(.data | tostring)"'
  done
}
