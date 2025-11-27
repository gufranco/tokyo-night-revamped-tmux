#!/usr/bin/env bash

get_widget_option() {
  local option="${1}"
  local default="${2:-0}"
  get_tmux_option "$option" "$default"
}

is_widget_feature_enabled() {
  local option="${1}"
  local default="${2:-1}"
  local value
  value=$(get_widget_option "$option" "$default")
  if [[ "$value" == "1" ]] || [[ "$value" == "true" ]] || [[ "$value" == "yes" ]]; then
    echo "1"
  else
    echo "0"
  fi
}

get_widget_threshold() {
  local option="${1}"
  local default="${2:-50}"
  get_widget_option "$option" "$default"
}

export -f get_widget_option
export -f is_widget_feature_enabled
export -f get_widget_threshold

