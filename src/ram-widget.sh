#!/usr/bin/env bash
# ==============================================================================
# Tokyo Night Tmux - RAM Widget
# ==============================================================================
# Displays RAM usage in GB/TB format (alternative to memory percentage widget).
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/tmux-config.sh"
source "${SCRIPT_DIR}/themes.sh"

if ! is_option_enabled "@tokyo-night-tmux_show_ram"; then
  exit 0
fi

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

get_ram_stats() {
  local os_type
  os_type="$(uname -s)"
  
  case "$os_type" in
    "Darwin")
      get_ram_stats_macos
      ;;
    "Linux")
      get_ram_stats_linux
      ;;
    *)
      echo "0 0 0"
      ;;
  esac
}

get_ram_stats_macos() {
  local total_ram used_ram
  
  total_ram=$(sysctl -n hw.memsize)
  
  local page_size
  page_size=$(pagesize 2>/dev/null || sysctl -n hw.pagesize)
  
  local vm_stat_output
  vm_stat_output=$(vm_stat)
  
  local pages_wired pages_active pages_compressed
  pages_wired=$(echo "$vm_stat_output" | awk '/Pages wired down/ {print $NF}' | tr -d '.')
  pages_active=$(echo "$vm_stat_output" | awk '/Pages active/ {print $NF}' | tr -d '.')
  pages_compressed=$(echo "$vm_stat_output" | awk '/Pages occupied by compressor/ {print $NF}' | tr -d '.')
  
  local used_pages
  used_pages=$(( pages_wired + pages_active + pages_compressed ))
  used_ram=$(( used_pages * page_size ))
  
  local percent
  percent=$(( (used_ram * 100) / total_ram ))
  
  echo "$used_ram $total_ram $percent"
}

get_ram_stats_linux() {
  local total_ram used_ram
  
  total_ram=$(awk '/MemTotal/ {print $2 * 1024}' /proc/meminfo)
  local available_ram
  available_ram=$(awk '/MemAvailable/ {print $2 * 1024}' /proc/meminfo)
  
  used_ram=$(( total_ram - available_ram ))
  
  local percent
  percent=$(( (used_ram * 100) / total_ram ))
  
  echo "$used_ram $total_ram $percent"
}

format_ram_size() {
  local bytes=$1
  local gb=$(( bytes / 1073741824 ))
  
  if (( gb >= 1000 )); then
    local tb=$(( (bytes * 10) / 10995116277760 ))
    local tb_int=$(( tb / 10 ))
    local tb_dec=$(( tb % 10 ))
    echo "${tb_int}.${tb_dec}T"
  else
    echo "${gb}G"
  fi
}

render_ram_widget() {
  local used total percent
  read -r used total percent <<< "$(get_ram_stats)"
  
  local icon color
  if (( percent >= 80 )); then
    icon="󰀪"
    color="#[fg=#f7768e,bg=default,bold]"  # Red
  elif (( percent >= 60 )); then
    icon="󰍜"
    color="#[fg=#e0af68,bg=default]"  # Yellow
  else
    icon="󰍛"
    color="#[fg=#73daca,bg=default]"  # Cyan
  fi
  
  local used_formatted total_formatted
  used_formatted=$(format_ram_size "$used")
  total_formatted=$(format_ram_size "$total")
  
  echo "${color}░ ${icon}${RESET} ${used_formatted}/${total_formatted} "
}

render_ram_widget

