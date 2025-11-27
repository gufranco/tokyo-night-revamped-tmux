#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."

source "${LIB_DIR}/tmux/tmux-ops.sh"

is_option_enabled() {
  local value
  value=$(get_tmux_option "${1}" "0")
  [[ "$value" == "1" || "$value" == "true" ]]
}

should_show_widget() {
  is_option_enabled "${1}"
}

is_widget_enabled() {
  should_show_widget "${1}"
}

get_numeric_option() {
  local value
  value=$(get_tmux_option "${1}" "${2}")

  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "${2}"
    return
  fi

  local min="${3:-0}"
  local max="${4:-999999}"

  (( value < min )) && echo "$min" && return
  (( value > max )) && echo "$max" && return
  echo "$value"
}

export -f is_option_enabled
export -f should_show_widget
export -f is_widget_enabled
export -f get_numeric_option

