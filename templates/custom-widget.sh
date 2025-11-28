#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "${PROJECT_ROOT}/src/lib/widget/widget-loader.sh"

is_minimal_session && exit 0

is_widget_enabled "@yoru_revamped_show_custom" || exit 0

cache_key="custom_widget"
cache_ttl=$(get_tmux_option "@yoru_revamped_custom_refresh" "5")

if is_cache_valid "$cache_key" "$cache_ttl"; then
  get_cached_value "$cache_key"
  exit 0
fi

get_custom_metric() {
  echo "42"
}

format_custom_output() {
  local metric="$1"

  local color
  color=$(get_system_color "$metric")

  local icon
  icon=$(format_icon "󰀅" "#7dcfff")

  local output
  output="${icon} ${color}${metric}%#[default]"

  echo "$output"
}

main() {
  local metric
  metric=$(get_custom_metric)

  local output
  output=$(format_custom_output "$metric")

  set_cached_value "$cache_key" "$output"

  echo "$output"
}

main

