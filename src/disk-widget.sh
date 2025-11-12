#!/usr/bin/env bash

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/coreutils-compat.sh"
. "${ROOT_DIR}/lib/tmux-config.sh"

# Check if enabled
SHOW_DISK=$(tmux show-option -gv @tokyo-night-tmux_show_disk 2>/dev/null)
[[ ${SHOW_DISK} -ne 1 ]] && exit 0

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/themes.sh"

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

DISK_PATH=$(get_tmux_option "@tokyo-night-tmux_disk_path" "/")

disk_info=$(df -h "$DISK_PATH" 2>/dev/null | awk 'NR==2 {print $5}')

if [[ -z "$disk_info" ]]; then
  exit 0
fi

usage_percent=$(echo "$disk_info" | tr -d '%')

if [[ ! "$usage_percent" =~ ^[0-9]+$ ]]; then
  usage_percent=0
fi

# Validate percentage
[[ "$usage_percent" -lt 0 ]] && usage_percent="0"
[[ "$usage_percent" -gt 100 ]] && usage_percent="100"

# 4 levels of warning (more granular than CPU/Memory, matches iStats)
if (( usage_percent >= 90 )); then
  icon="󰀪"  # Critical - alert icon
  color="#[fg=${THEME[red]},bg=default,bold]"  # Red bold
elif (( usage_percent >= 75 )); then
  icon="󰪥"  # High - warning icon
  color="#[fg=${THEME[yellow]},bg=default]"  # Yellow
elif (( usage_percent >= 50 )); then
  icon="󰋊"  # Medium
  color="#[fg=${THEME[blue]},bg=default]"  # Blue
else
  icon="󰋊"  # Normal
  color="#[fg=${THEME[cyan]},bg=default]"  # Cyan
fi

# Build output (consistent format: separator + icon + value)
echo "${color}░ ${icon}${RESET} ${usage_percent}% "

