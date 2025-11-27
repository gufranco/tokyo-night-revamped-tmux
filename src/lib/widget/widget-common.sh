#!/usr/bin/env bash

get_widget_cache_key() {
  local widget_name="${1}"
  local suffix="${2:-}"

  if [[ -n "$suffix" ]]; then
    echo "${widget_name}_${suffix}"
  else
    echo "$widget_name"
  fi
}

get_cached_widget_output() {
  local widget_name="${1}"
  local cache_key
  cache_key=$(get_widget_cache_key "$widget_name" "${2:-}")
  local refresh_rate
  refresh_rate=$(get_cached_refresh_rate)

  get_cached_value "$cache_key" "$refresh_rate"
}

should_use_cache() {
  local cached_output="${1}"
  [[ -n "$cached_output" ]]
}

validate_widget_enabled() {
  local option="${1}"
  is_widget_enabled "$option" || exit 0
}

validate_minimal_session() {
  is_minimal_session && exit 0
}

export -f get_widget_cache_key
export -f get_cached_widget_output
export -f should_use_cache
export -f validate_widget_enabled
export -f validate_minimal_session

