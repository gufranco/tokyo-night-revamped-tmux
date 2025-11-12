#!/usr/bin/env bash

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/coreutils-compat.sh"

# Check if enabled
SHOW_CPU=$(tmux show-option -gv @tokyo-night-tmux_show_cpu 2>/dev/null)
[[ ${SHOW_CPU} -ne 1 ]] && exit 0

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/themes.sh"

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# Configuration
SHOW_LOAD=$(tmux show-option -gv @tokyo-night-tmux_show_load_average 2>/dev/null)
SHOW_LOAD="${SHOW_LOAD:-0}"  # Default: disabled

cpu_usage="0"

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS: use top (matches Activity Monitor/iStats calculation)
  # -l 1 for speed, -n 0 for no process list
  cpu_line=$(top -l 1 -n 0 | grep "CPU usage")
  cpu_user=$(echo "$cpu_line" | awk '{print $3}' | sed 's/%//')
  cpu_sys=$(echo "$cpu_line" | awk '{print $5}' | sed 's/%//')

  # Calculate total (user + system) like iStats Menu
  if command -v bc >/dev/null 2>&1; then
    cpu_usage=$(echo "$cpu_user + $cpu_sys" | bc | cut -d'.' -f1)
  else
    # Fallback without bc (less precise but works)
    cpu_usage=$(awk "BEGIN {printf \"%.0f\", $cpu_user + $cpu_sys}")
  fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux: read from /proc/stat
  read -r _ user nice system idle _ < /proc/stat
  total_initial=$((user + nice + system + idle))
  idle_initial=$idle

  sleep 0.1

  read -r _ user nice system idle _ < /proc/stat
  total_final=$((user + nice + system + idle))
  idle_final=$idle

  total_diff=$((total_final - total_initial))
  idle_diff=$((idle_final - idle_initial))

  if [[ $total_diff -gt 0 ]]; then
    cpu_usage=$(( (total_diff - idle_diff) * 100 / total_diff ))
  fi
else
  echo "#[nobold,fg=$ACCENT_COLOR]░  ${RESET}N/A "
  exit 0
fi

# Validate CPU usage
[[ -z "$cpu_usage" ]] && cpu_usage="0"
[[ "$cpu_usage" -lt 0 ]] && cpu_usage="0"
[[ "$cpu_usage" -gt 100 ]] && cpu_usage="100"

# Set icon and color based on CPU usage (matches iStats thresholds)
if [[ $cpu_usage -ge 80 ]]; then
  icon="󰀪"  # High CPU (hot)
  color="#[fg=${THEME[red]},bg=default,bold]"  # Red
elif [[ $cpu_usage -ge 50 ]]; then
  icon="󰾅"  # Medium CPU
  color="#[fg=${THEME[yellow]},bg=default]"  # Yellow
else
  icon="󰾆"  # Low CPU (cool)
  color="#[fg=${THEME[cyan]},bg=default]"  # Cyan
fi

# Build output (consistent format: separator + icon + value)
output="${color}░ ${icon}${RESET} ${cpu_usage}%"

# Add load average if enabled
if [[ $SHOW_LOAD -eq 1 ]]; then
  # Get 1-minute load average
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: use sysctl
    load_avg=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
  else
    # Linux: read from /proc/loadavg
    load_avg=$(cat /proc/loadavg 2>/dev/null | awk '{print $1}')
  fi

  [[ -n "$load_avg" ]] && output="${output} ${RESET}#[dim]󰑮${RESET} ${load_avg}"
fi

echo "${output} "

