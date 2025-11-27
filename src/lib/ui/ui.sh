#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/themes.sh" ]]; then
  source "${SCRIPT_DIR}/themes.sh"
fi

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"


format_segment() {
  local content="${1}"
  local fg_color="${2:-${THEME[foreground]}}"
  local bg_color="${3:-${THEME[background]}}"
  
  echo "#[fg=${fg_color},bg=${bg_color}]${content}${RESET}"
}

format_icon() {
  local icon="${1}"
  local color="${2:-${THEME[foreground]}}"
  local style="${3:-nobold}"
  
  echo "#[fg=${color},bg=default,${style}]${icon}"
}

format_percentage_value() {
  local value="${1}"
  local color="${2:-${THEME[foreground]}}"
  
  echo "#[fg=${color}]${value}%${RESET}"
}

format_count() {
  local count="${1}"
  local color="${2:-${THEME[foreground]}}"
  local icon="${3}"
  
  if [[ -n "${icon}" ]]; then
    echo "#[fg=${color}]${icon} ${count}${RESET} "
  else
    echo "#[fg=${color}]${count}${RESET} "
  fi
}

format_latency() {
  local ms="${1}"
  local color
  
  if (( ms < 50 )); then
    color="${THEME[cyan]}"
  elif (( ms < 100 )); then
    color="${THEME[blue]}"
  elif (( ms < 200 )); then
    color="${THEME[yellow]}"
  else
    color="${THEME[red]}"
  fi
  
  echo "#[fg=${color}]󰖩 ${ms}ms${RESET} "
}

format_bytes() {
  local bytes="${1}"
  local result
  
  if (( bytes >= 1073741824 )); then
    result=$(( (bytes * 10) / 1073741824 ))
    echo "$((result / 10)).$((result % 10))G"
  elif (( bytes >= 1048576 )); then
    result=$(( (bytes * 10) / 1048576 ))
    echo "$((result / 10)).$((result % 10))M"
  elif (( bytes >= 1024 )); then
    result=$(( (bytes * 10) / 1024 ))
    echo "$((result / 10)).$((result % 10))K"
  else
    echo "${bytes}B"
  fi
}

format_status() {
  local status="${1}"
  local color="${2:-${THEME[foreground]}}"
  
  echo "#[fg=${color}]${status}${RESET}"
}

format_progress_bar() {
  local percentage="${1}"
  local width="${2:-10}"
  local filled_char="${3:-█}"
  local empty_char="${4:-░}"
  
  local filled=$(( (percentage * width) / 100 ))
  local empty=$(( width - filled ))
  
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="${filled_char}"; done
  for ((i=0; i<empty; i++)); do bar+="${empty_char}"; done
  
  echo "[${bar}]"
}


export -f format_segment
export -f format_icon
export -f format_percentage_value
export -f format_count
export -f format_latency
export -f format_bytes
export -f format_status
export -f format_progress_bar

