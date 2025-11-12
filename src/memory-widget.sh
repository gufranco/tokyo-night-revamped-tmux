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

SHOW_MEMORY_PRESSURE=$(tmux show-option -gv @tokyo-night-tmux_show_memory_pressure 2>/dev/null)
SHOW_MEMORY_PRESSURE="${SHOW_MEMORY_PRESSURE:-0}"

memory_percent=0

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS: use vm_stat and sysctl (matches iStats Menu calculation)
  total_mem=$(sysctl -n hw.memsize)
  page_size=$(pagesize 2>/dev/null || sysctl -n hw.pagesize)

  # Parse vm_stat output using $NF (last field) for robustness
  vm_stats=$(vm_stat)
  pages_wired=$(echo "$vm_stats" | awk '/Pages wired down/ {print $NF}' | tr -d '.')
  pages_compressed=$(echo "$vm_stats" | awk '/Pages occupied by compressor/ {print $NF}' | tr -d '.')

  # Calculate App Memory (same as iStats Menu calculation)
  # iStats uses: wired + compressed (NOT including active pages)
  # This matches "Memory Used" in iStats Menu and represents non-swappable memory
  used_pages=$((pages_wired + pages_compressed))
  used_mem=$((used_pages * page_size))

  # Calculate percentage
  memory_percent=$(( (used_mem * 100) / total_mem ))
  
elif command -v free >/dev/null 2>&1; then
  # Linux: use /proc/meminfo for accurate calculation
  total_mem=$(awk '/MemTotal/ {print $2 * 1024}' /proc/meminfo)
  available_mem=$(awk '/MemAvailable/ {print $2 * 1024}' /proc/meminfo)
  
  # Calculate used memory (total - available)
  used_mem=$(( total_mem - available_mem ))
  
  # Calculate percentage
  memory_percent=$(( (used_mem * 100) / total_mem ))
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

output="${color}░ ${icon}${RESET} ${memory_percent}% "

# Add memory pressure indicator if enabled
if [[ "${SHOW_MEMORY_PRESSURE}" == "1" ]]; then
  pressure_color=""
  pressure_icon="●"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Check swapouts from vm_stat (reuse existing vm_stats)
    swapouts=$(echo "$vm_stats" | grep "Swapouts:" | awk '{print $NF}' | tr -d '.')

    if (( swapouts > 5000000 )); then
      pressure_color="${THEME[red]}"      # Critical pressure
    elif (( swapouts > 1000000 )); then
      pressure_color="${THEME[yellow]}"   # Medium pressure
    else
      pressure_color="${THEME[green]}"    # No pressure
    fi
  else
    # Linux: Check PSI (Pressure Stall Information) if available
    if [[ -f /proc/pressure/memory ]]; then
      pressure_some=$(grep "some" /proc/pressure/memory | awk '{print $2}' | cut -d'=' -f2 | cut -d'.' -f1)

      if (( pressure_some > 50 )); then
        pressure_color="${THEME[red]}"
      elif (( pressure_some > 10 )); then
        pressure_color="${THEME[yellow]}"
      else
        pressure_color="${THEME[green]}"
      fi
    else
      # Fallback: check swap usage
      swap_total=$(free | grep Swap | awk '{print $2}')
      swap_used=$(free | grep Swap | awk '{print $3}')

      if [[ "$swap_total" -gt 0 ]] && [[ "$swap_used" -gt 0 ]]; then
        swap_percent=$(( (swap_used * 100) / swap_total ))

        if (( swap_percent > 50 )); then
          pressure_color="${THEME[red]}"
        elif (( swap_percent > 10 )); then
          pressure_color="${THEME[yellow]}"
        else
          pressure_color="${THEME[green]}"
        fi
      else
        pressure_color="${THEME[green]}"
      fi
    fi
  fi

  if [[ -n "$pressure_color" ]]; then
    output+="#[fg=${pressure_color}]${pressure_icon} "
  fi
fi

echo "$output"
