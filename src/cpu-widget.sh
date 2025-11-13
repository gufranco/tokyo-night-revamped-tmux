#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${SCRIPT_DIR}/themes.sh"

# ==============================================================================
# Configuration
# ==============================================================================

# Exit if not enabled
is_widget_enabled "@tokyo-night-tmux_show_cpu" || exit 0

SHOW_LOAD=$(tmux show-option -gv @tokyo-night-tmux_show_load_average 2>/dev/null)
SHOW_LOAD="${SHOW_LOAD:-0}"

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# ==============================================================================
# CPU Usage Calculation
# ==============================================================================

get_cpu_usage_macos() {
  local cpu_line cpu_user cpu_sys
  
  cpu_line=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage") || return 1
  cpu_user=$(echo "$cpu_line" | awk '{print $3}' | sed 's/%//')
  cpu_sys=$(echo "$cpu_line" | awk '{print $5}' | sed 's/%//')

  # Calculate total (user + system) - matches iStats Menu
  if command -v bc >/dev/null 2>&1; then
    echo "$cpu_user + $cpu_sys" | bc 2>/dev/null | cut -d'.' -f1
  else
    awk "BEGIN {printf \"%.0f\", $cpu_user + $cpu_sys}" 2>/dev/null
  fi
}

get_cpu_usage_linux() {
  local user nice system idle
  local total_initial idle_initial
  local total_final idle_final
  local total_diff idle_diff
  
  read -r _ user nice system idle _ < /proc/stat || return 1
  total_initial=$((user + nice + system + idle))
  idle_initial=$idle

  sleep 0.1

  read -r _ user nice system idle _ < /proc/stat || return 1
  total_final=$((user + nice + system + idle))
  idle_final=$idle

  total_diff=$((total_final - total_initial))
  idle_diff=$((idle_final - idle_initial))

  if [[ $total_diff -gt 0 ]]; then
    echo $(( (total_diff - idle_diff) * 100 / total_diff ))
else
    echo "0"
  fi
}

get_cpu_usage() {
  local usage
  
  if is_macos; then
    usage=$(get_cpu_usage_macos)
  elif is_linux; then
    usage=$(get_cpu_usage_linux)
  else
    echo "0"
    return
  fi
  
  validate_percentage "${usage:-0}"
}

# ==============================================================================
# Load Average
# ==============================================================================

get_load_average() {
  local load_avg
  
  if is_macos; then
    load_avg=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
  elif is_linux; then
    load_avg=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
  fi
  
  echo "${load_avg}"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
  local cpu_usage icon color output
  
  # Get CPU usage
  cpu_usage=$(get_cpu_usage)
  
  # Get icon and color
  icon=$(get_cpu_icon "$cpu_usage")
  color=$(get_color_3tier "$cpu_usage" "${THEME[red]}" "${THEME[yellow]}" "${THEME[cyan]}")
  
  # Build output
  output=$(format_widget_output "$color" "$icon" "$cpu_usage" "%" "$RESET")
  
  # Add load average if enabled
  if [[ $SHOW_LOAD -eq 1 ]]; then
    local load_avg
    load_avg=$(get_load_average)
    
    if [[ -n "$load_avg" ]]; then
      output="${output}${RESET}#[dim]${ICON_LOAD}${RESET} ${load_avg} "
    fi
fi

  echo "$output"
}

main
