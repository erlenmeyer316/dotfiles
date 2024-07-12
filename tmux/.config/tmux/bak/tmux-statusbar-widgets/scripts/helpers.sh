#!/usr/bin/env bash

export LANG=C
export LC_ALL=C

get_tmux_option() {
  local option
  local default_value
  local option_value
  option="$1"
  default_value="$2"
  option_value="$(tmux show-option -qv "$option")"
  if [ -z "$option_value" ]; then
    option_value="$(tmux show-option -gqv "$option")"
  fi
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}



command_exists() {
  local command
  command="$1"
  command -v "$command" &>/dev/null
}

get_tmp_dir() {
  local tmpdir
  tmpdir="${TMPDIR:-${TMP:-${TEMP:-/tmp}}}"
  [ -d "$tmpdir" ] || local tmpdir=~/tmp
  echo "$tmpdir/tmux-$EUID-statusbar-widgets"
}

get_time() {
  date +%s.%N
}

get_cache_val() {
  local key
  local timeout
  local cache
  key="$1"
  # seconds after which cache is invalidated
  timeout="${2:-2}"
  cache="$(get_tmp_dir)/$key"
  if [ -f "$cache" ]; then
    awk -v cache="$(head -n1 "$cache")" -v timeout="$timeout" -v now="$(get_time)" \
      'BEGIN {if (now - timeout < cache) exit 0; exit 1}' &&
      tail -n+2 "$cache"
  fi
}

put_cache_val() {
  local key
  local val
  local tmpdir
  key="$1"
  val="${*:2}"
  tmpdir="$(get_tmp_dir)"
  [ ! -d "$tmpdir" ] && mkdir -p "$tmpdir" && chmod 0700 "$tmpdir"
  (
    get_time
    echo -n "$val"
  ) >"$tmpdir/$key"
  echo -n "$val"
}

cached_eval() {
  local command
  local key
  local val
  command="$1"
  key="$(basename "$command")"
  val="$(get_cache_val "$key")"
  if [ -z "$val" ]; then
    put_cache_val "$key" "$($command "${@:2}")"
  else
    echo -n "$val"
  fi
}
