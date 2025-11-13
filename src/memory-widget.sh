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
is_widget_enabled "@tokyo-night-tmux_show_memory" || exit 0

SHOW_PRESSURE=$(tmux show-option -gv @tokyo-night-tmux_show_memory_pressure 2>/dev/null)
SHOW_PRESSURE="${SHOW_PRESSURE:-0}"

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# ==============================================================================
# Memory Calculation (iStats Menu Method)
# ==============================================================================

get_memory_usage_macos() {
  local total_mem page_size vm_stats
  local pages_wired pages_compressed
  local used_pages used_mem
  
  total_mem=$(sysctl -n hw.memsize 2>/dev/null) || return 1
  page_size=$(pagesize 2>/dev/null || sysctl -n hw.pagesize 2>/dev/null) || return 1
  
  vm_stats=$(vm_stat 2>/dev/null) || return 1
  pages_wired=$(echo "$vm_stats" | awk '/Pages wired down/ {print $NF}' | tr -d '.')
  pages_compressed=$(echo "$vm_stats" | awk '/Pages occupied by compressor/ {print $NF}' | tr -d '.')

  # iStats method: wired + compressed only (not active)
  used_pages=$((pages_wired + pages_compressed))
  used_mem=$((used_pages * page_size))

  echo $(( (used_mem * 100) / total_mem ))
}

get_memory_usage_linux() {
  local total_mem available_mem used_mem
  
  total_mem=$(awk '/MemTotal/ {print $2 * 1024}' /proc/meminfo 2>/dev/null) || return 1
  available_mem=$(awk '/MemAvailable/ {print $2 * 1024}' /proc/meminfo 2>/dev/null) || return 1
  
  used_mem=$(( total_mem - available_mem ))
  
  echo $(( (used_mem * 100) / total_mem ))
}

get_memory_usage() {
  local usage
  
  if is_macos; then
    usage=$(get_memory_usage_macos)
  elif is_linux; then
    usage=$(get_memory_usage_linux)
  else
    echo "0"
    return
  fi
  
  validate_percentage "${usage:-0}"
}

# ==============================================================================
# Memory Pressure Indicator
# ==============================================================================

get_memory_pressure_macos() {
  local vm_stats swapouts
  
  vm_stats=$(vm_stat 2>/dev/null) || return 1
    swapouts=$(echo "$vm_stats" | grep "Swapouts:" | awk '{print $NF}' | tr -d '.')

  [[ -z "$swapouts" ]] && return 1
  
  if (( swapouts > PRESSURE_CRITICAL_SWAPOUTS )); then
    echo "${THEME[red]}"
  elif (( swapouts > PRESSURE_WARNING_SWAPOUTS )); then
    echo "${THEME[yellow]}"
  else
    echo "${THEME[green]}"
  fi
}

get_memory_pressure_linux() {
  local pressure_some
  
  [[ ! -f /proc/pressure/memory ]] && return 1
  
  pressure_some=$(grep "some" /proc/pressure/memory 2>/dev/null | awk '{print $2}' | cut -d'=' -f2 | cut -d'.' -f1)
  
  [[ -z "$pressure_some" ]] && return 1

  if (( pressure_some > PRESSURE_CRITICAL_PSI )); then
    echo "${THEME[red]}"
  elif (( pressure_some > PRESSURE_WARNING_PSI )); then
    echo "${THEME[yellow]}"
      else
    echo "${THEME[green]}"
      fi
}

get_memory_pressure_color() {
  local pressure_color
  
  if is_macos; then
    pressure_color=$(get_memory_pressure_macos)
  elif is_linux; then
    pressure_color=$(get_memory_pressure_linux)
  fi
  
  echo "${pressure_color}"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
  local memory_usage icon color output
  
  # Get memory usage
  memory_usage=$(get_memory_usage)
  
  # Get icon and color
  icon=$(get_memory_icon "$memory_usage")
  color=$(get_color_3tier "$memory_usage" "${THEME[red]}" "${THEME[yellow]}" "${THEME[cyan]}")
  
  # Build output
  output=$(format_widget_output "$color" "$icon" "$memory_usage" "%" "$RESET")
  
  # Add memory pressure indicator if enabled
  if [[ $SHOW_PRESSURE -eq 1 ]]; then
    local pressure_color
    pressure_color=$(get_memory_pressure_color)

  if [[ -n "$pressure_color" ]]; then
      output="${output}#[fg=${pressure_color}]${ICON_MEMORY_PRESSURE}${RESET} "
  fi
fi

echo "$output"
}

main
