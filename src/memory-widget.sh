#!/usr/bin/env bash

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/coreutils-compat.sh"

# Check if enabled
SHOW_MEMORY=$(tmux show-option -gv @tokyo-night-tmux_show_memory 2>/dev/null)
[[ ${SHOW_MEMORY} -ne 1 ]] && exit 0

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/themes.sh"

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

memory_percent=0

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS: use vm_stat and sysctl (no compilation needed)
  page_size=$(sysctl -n hw.pagesize)
  total_mem=$(sysctl -n hw.memsize)

  # Parse vm_stat output
  vm_stats=$(vm_stat)
  pages_active=$(echo "$vm_stats" | awk '/Pages active/ {print $3}' | tr -d '.')
  pages_wired=$(echo "$vm_stats" | awk '/Pages wired down/ {print $4}' | tr -d '.')
  pages_compressed=$(echo "$vm_stats" | awk '/Pages occupied by compressor/ {print $5}' | tr -d '.')

  # Calculate App Memory (same as Activity Monitor/iStats)
  # Only includes: active + wired + compressed (excludes inactive/cached)
  used_pages=$((pages_active + pages_wired + pages_compressed))
  used_mem=$((used_pages * page_size))

  # Calculate percentage
  memory_percent=$(( used_mem * 100 / total_mem ))
  
elif command -v free >/dev/null 2>&1; then
  # Linux: use free command
  mem_info=$(free -b | awk 'NR==2 {print $2, $3}')
  total_mem=$(echo "$mem_info" | awk '{print $1}')
  used_mem=$(echo "$mem_info" | awk '{print $2}')
  
  # Calculate percentage
  memory_percent=$(( used_mem * 100 / total_mem ))
else
  echo "#[nobold,fg=${THEME[cyan]}]░ 󰍛 ${RESET}N/A "
  exit 0
fi

# Validate memory percentage
[[ -z "$memory_percent" ]] && memory_percent="0"
[[ "$memory_percent" -lt 0 ]] && memory_percent="0"
[[ "$memory_percent" -gt 100 ]] && memory_percent="100"

# Set icon and color based on memory usage
if [[ $memory_percent -ge 80 ]]; then
  icon="󰀪"  # High memory (critical)
  color="#[fg=#f7768e,bg=default,bold]"  # Red
elif [[ $memory_percent -ge 60 ]]; then
  icon="󰍜"  # Medium-high memory
  color="#[fg=#e0af68,bg=default]"  # Yellow
else
  icon="󰍛"  # Low memory
  color="#[fg=#73daca,bg=default]"  # Cyan
fi

echo "${color}░ ${icon}${RESET} ${memory_percent}% "

