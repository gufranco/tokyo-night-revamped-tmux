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
is_widget_enabled "@tokyo-night-tmux_show_disk" || exit 0

DISK_PATH=$(tmux show-option -gv @tokyo-night-tmux_disk_path 2>/dev/null)
DISK_PATH="${DISK_PATH:-/}"

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# ==============================================================================
# Disk Usage Calculation
# ==============================================================================

get_disk_usage() {
  local disk_info usage_percent

  disk_info=$(df -h "$1" 2>/dev/null | awk 'NR==2 {print $5}') || return 1
usage_percent=$(echo "$disk_info" | tr -d '%')

  validate_percentage "$usage_percent"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
  local disk_usage icon color output
  
  # Get disk usage
  disk_usage=$(get_disk_usage "$DISK_PATH")
  
  [[ -z "$disk_usage" ]] && exit 0
  
  # Get icon and color (4-tier system)
  icon=$(get_disk_icon "$disk_usage")
  color=$(get_color_4tier "$disk_usage" "${THEME[red]}" "${THEME[yellow]}" "${THEME[blue]}" "${THEME[cyan]}")
  
  # Build output
  output=$(format_widget_output "$color" "$icon" "$disk_usage" "%" "$RESET")
  
  echo "$output"
}

main
