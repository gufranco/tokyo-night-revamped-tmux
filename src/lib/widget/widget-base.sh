#!/usr/bin/env bash

validate_percentage() {
  local value="${1}"

  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "1"
    return
  fi

  if (( value <= 0 )); then
    echo "1"
  elif (( value > 100 )); then
    echo "100"
  else
    echo "$value"
  fi
}

validate_number() {
  local value="${1}"
  local default="${2:-0}"

  if [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "$value"
  else
    echo "$default"
  fi
}

get_color_3tier() {
  local value="${1}"
  local theme_red="${2}"
  local theme_yellow="${3}"
  local theme_cyan="${4}"

  if (( value >= 80 )); then
    echo "${theme_red},bold"
  elif (( value >= 50 )); then
    echo "${theme_yellow}"
  else
    echo "${theme_cyan}"
  fi
}

get_color_4tier() {
  local value="${1}"
  local theme_red="${2}"
  local theme_yellow="${3}"
  local theme_blue="${4}"
  local theme_cyan="${5}"

  if (( value >= 90 )); then
    echo "${theme_red},bold"
  elif (( value >= 75 )); then
    echo "${theme_yellow}"
  elif (( value >= 50 )); then
    echo "${theme_blue}"
  else
    echo "${theme_cyan}"
  fi
}

get_cpu_icon() {
  local usage="${1}"

  if (( usage >= 80 )); then
    echo "󰀪"
  elif (( usage >= 50 )); then
    echo "󰾅"
  else
    echo "󰾆"
  fi
}

get_memory_icon() {
  local usage="${1}"

  if (( usage >= 80 )); then
    echo "󰀪"
  elif (( usage >= 60 )); then
    echo "󰍜"
  else
    echo "󰍛"
  fi
}

get_disk_icon() {
  local usage="${1}"

  if (( usage >= 90 )); then
    echo "󰀪"
  elif (( usage >= 75 )); then
    echo "󰪥"
  else
    echo "󰋊"
  fi
}

format_widget_output() {
  local color="${1}"
  local icon="${2}"
  local value="${3}"
  local unit="${4:-%}"
  local reset="${5}"

  echo "#[fg=${color},bg=default]░ ${icon}${reset} ${value}${unit} "
}

format_widget_value() {
  local color="${1}"
  local icon="${2}"
  local value="${3}"
  local unit="${4:-%}"
  local reset="${5}"

  echo "#[fg=${color},bg=default]${icon}${reset} ${value}${unit}"
}


is_widget_enabled() {
  local option_name="${1}"
  local value
  value=$(tmux show-option -gv "${option_name}" 2>/dev/null)

  [[ "${value}" == "1" ]]
}

export -f validate_percentage
export -f validate_number
export -f get_color_3tier
export -f get_color_4tier
export -f get_cpu_icon
export -f get_memory_icon
export -f get_disk_icon
export -f format_widget_output
export -f format_widget_value
export -f is_widget_enabled
