#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."

source "${LIB_DIR}/utils/platform-cache.sh"
source "${LIB_DIR}/utils/tmux-cache.sh"
source "${LIB_DIR}/utils/coreutils-compat.sh"

CACHE_DIR="/tmp/tmux_yoru_cache"
mkdir -p "$CACHE_DIR" 2>/dev/null

get_refresh_rate() {
  get_cached_refresh_rate
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
  cache_time=$(get_file_mtime "$cache_file")

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

  if [[ ! -w "$CACHE_DIR" ]] 2>/dev/null; then
    return 1
  fi

  echo "$value" > "$cache_file" 2>/dev/null
}

invalidate_cache() {
  local widget_name="${1:-}"

  if [[ -z "$widget_name" ]]; then
    rm -f "${CACHE_DIR}"/*.cache 2>/dev/null
    if declare -f invalidate_tmux_cache >/dev/null 2>&1; then
      invalidate_tmux_cache
    fi
    return 0
  fi

  local cache_file
  cache_file=$(get_cache_file "$widget_name")
  rm -f "$cache_file" 2>/dev/null
}

clear_all_caches() {
  invalidate_cache
}

export -f get_refresh_rate
export -f get_cache_file
export -f is_cache_valid
export -f get_cached_value
export -f set_cached_value
export -f invalidate_cache
export -f clear_all_caches
