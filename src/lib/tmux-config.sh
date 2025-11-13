#!/usr/bin/env bash

get_tmux_option() {
  local option_name="${1}"
  local default_value="${2:-}"
  
  local value
  value=$(tmux show-option -gv "${option_name}" 2>/dev/null)
  
  if [[ -z "${value}" ]]; then
    echo "${default_value}"
  else
    echo "${value}"
  fi
}

is_option_enabled() {
  local option_name="${1}"
  local value
  value=$(get_tmux_option "${option_name}" "0")
  
  [[ "${value}" == "1" || "${value}" == "true" ]]
}

should_show_widget() {
  local widget_option="${1}"
  is_option_enabled "${widget_option}"
}

get_numeric_option() {
  local option_name="${1}"
  local default="${2}"
  local min="${3:-0}"
  local max="${4:-999999}"
  
  local value
  value=$(get_tmux_option "${option_name}" "${default}")
  
  if ! [[ "${value}" =~ ^[0-9]+$ ]]; then
    echo "${default}"
    return
  fi
  
  if (( value < min )); then
    echo "${min}"
  elif (( value > max )); then
    echo "${max}"
  else
    echo "${value}"
  fi
}

export -f get_tmux_option
export -f is_option_enabled
export -f should_show_widget
export -f get_numeric_option

