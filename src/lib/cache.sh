#!/usr/bin/env bash

CACHE_DIR="/tmp/tmux_tokyo_night_cache"
mkdir -p "$CACHE_DIR" 2>/dev/null

is_macos() {
  [[ "$OSTYPE" == "darwin"* ]]
}

get_refresh_rate() {
  local rate
  rate=$(tmux show-option -gv @tokyo-night-tmux_refresh_rate 2>/dev/null)
  echo "${rate:-5}"
}

get_cache_file() {
  local widget_name=$1
  echo "${CACHE_DIR}/${widget_name}.cache"
}

is_cache_valid() {
  local cache_file=$1
  local refresh_rate=$2

  [[ ! -f "$cache_file" ]] && return 1

  local cache_time current_time cache_age

  if is_macos; then
    cache_time=$(stat -f "%m" "$cache_file" 2>/dev/null)
  else
    cache_time=$(stat -c "%Y" "$cache_file" 2>/dev/null)
  fi

  [[ -z "$cache_time" ]] && return 1
  [[ ! "$cache_time" =~ ^[0-9]+$ ]] && return 1

  current_time=$(date +%s)
  cache_age=$((current_time - cache_time))

  (( cache_age < refresh_rate ))
}

get_cached_value() {
  local widget_name=$1
  local refresh_rate=$2
  local cache_file

  cache_file=$(get_cache_file "$widget_name")

  if is_cache_valid "$cache_file" "$refresh_rate"; then
    cat "$cache_file" 2>/dev/null
    return 0
  fi

  return 1
}

set_cached_value() {
  local widget_name=$1
  local value=$2
  local cache_file

  cache_file=$(get_cache_file "$widget_name")
  echo "$value" > "$cache_file" 2>/dev/null
}

export -f get_refresh_rate
export -f get_cache_file
export -f is_cache_valid
export -f get_cached_value
export -f set_cached_value
