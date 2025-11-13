#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${SCRIPT_DIR}/themes.sh"

is_widget_enabled "@tokyo-night-tmux_show_ram" || exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

get_ram_stats_macos() {
  local total_ram page_size vm_output
  local pages_wired pages_active pages_compressed
  local used_pages used_ram percent
  
  total_ram=$(sysctl -n hw.memsize 2>/dev/null) || return 1
  page_size=$(pagesize 2>/dev/null || sysctl -n hw.pagesize 2>/dev/null) || return 1
  
  vm_output=$(vm_stat 2>/dev/null) || return 1
  
  pages_wired=$(echo "$vm_output" | awk '/Pages wired down/ {print $NF}' | tr -d '.')
  pages_active=$(echo "$vm_output" | awk '/Pages active/ {print $NF}' | tr -d '.')
  pages_compressed=$(echo "$vm_output" | awk '/Pages occupied by compressor/ {print $NF}' | tr -d '.')
  
  used_pages=$(( pages_wired + pages_active + pages_compressed ))
  used_ram=$(( used_pages * page_size ))
  percent=$(( (used_ram * 100) / total_ram ))
  
  echo "$used_ram $total_ram $percent"
}

get_ram_stats_linux() {
  local total_ram available_ram used_ram percent
  
  total_ram=$(awk '/MemTotal/ {print $2 * 1024}' /proc/meminfo 2>/dev/null) || return 1
  available_ram=$(awk '/MemAvailable/ {print $2 * 1024}' /proc/meminfo 2>/dev/null) || return 1
  
  used_ram=$(( total_ram - available_ram ))
  percent=$(( (used_ram * 100) / total_ram ))
  
  echo "$used_ram $total_ram $percent"
}

format_ram_size() {
  local bytes=$1
  local gb=$(( bytes / 1073741824 ))
  
  if (( gb >= 1000 )); then
    local tb=$(( (bytes * 10) / 10995116277760 ))
    echo "$((tb / 10)).$((tb % 10))T"
  else
    echo "${gb}G"
  fi
}

main() {
  local used total percent used_fmt total_fmt icon color
  
  if is_macos; then
    read -r used total percent <<< "$(get_ram_stats_macos)" || exit 0
  else
    read -r used total percent <<< "$(get_ram_stats_linux)" || exit 0
  fi
  
  icon=$(get_memory_icon "$percent")
  color=$(get_color_3tier "$percent" "${THEME[red]}" "${THEME[yellow]}" "${THEME[cyan]}")
  
  used_fmt=$(format_ram_size "$used")
  total_fmt=$(format_ram_size "$total")
  
  echo "#[fg=${color},bg=default]░ ${icon}${RESET} ${used_fmt}/${total_fmt} "
}

main
