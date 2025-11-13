#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${SCRIPT_DIR}/themes.sh"

is_widget_enabled "@tokyo-night-tmux_show_battery_widget" || exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

BATTERY_NAME=$(tmux show-option -gv @tokyo-night-tmux_battery_name 2>/dev/null)
BATTERY_LOW=$(tmux show-option -gv @tokyo-night-tmux_battery_low_threshold 2>/dev/null)
BATTERY_LOW="${BATTERY_LOW:-$DEFAULT_BATTERY_LOW}"

if is_macos; then
  BATTERY_NAME="${BATTERY_NAME:-InternalBattery-0}"
else
  BATTERY_NAME="${BATTERY_NAME:-BAT1}"
fi

battery_exists() {
  if is_macos; then
    pmset -g batt 2>/dev/null | grep -q "$BATTERY_NAME"
  else
    [[ -d "/sys/class/power_supply/$BATTERY_NAME" ]]
  fi
}

battery_exists || exit 0

get_battery_stats_macos() {
  local ac_power pmstat battery_status battery_percentage
  
  ac_power=$(pmset -g batt 2>/dev/null | head -1 | grep -i "AC Power")
  pmstat=$(pmset -g batt 2>/dev/null | grep "$BATTERY_NAME")
  
    battery_status=$(echo "$pmstat" | awk '{print $4}' | sed 's/[^a-zA-Z]*//g')
    battery_percentage=$(echo "$pmstat" | awk '{print $3}' | sed 's/[^0-9]*//g')

  [[ -n "$ac_power" ]] && battery_status="charging"
  
  echo "$battery_status $battery_percentage"
}

get_battery_stats_linux() {
  local battery_status battery_percentage
  
  [[ ! -f "/sys/class/power_supply/${BATTERY_NAME}/status" ]] && return 1
  [[ ! -f "/sys/class/power_supply/${BATTERY_NAME}/capacity" ]] && return 1
  
  battery_status=$(<"/sys/class/power_supply/${BATTERY_NAME}/status")
  battery_percentage=$(<"/sys/class/power_supply/${BATTERY_NAME}/capacity")

  local adapter
      for adapter in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
    [[ ! -f "$adapter" ]] && continue
    [[ $(<"$adapter") -eq 1 ]] && battery_status="charging" && break
  done
  
  echo "$battery_status $battery_percentage"
}

get_battery_icon() {
  local status="${1}"
  local percentage="${2}"
  
  local status_lower
  status_lower=$(echo "$status" | tr '[:upper:]' '[:lower:]')

  case "${status_lower}" in
charging|charged|full|ac)
      echo "${ICON_BATTERY_PLUG}"
  ;;
discharging)
      local icon_idx=$(( percentage / 10 ))
      (( icon_idx > 10 )) && icon_idx=10
      echo "${BATTERY_ICONS[$icon_idx]}"
  ;;
*)
      echo "${ICON_BATTERY_NO}"
  ;;
esac
}

get_battery_color() {
  local percentage="${1}"
  local threshold="${2}"
  
  if (( percentage < threshold )); then
    echo "${THEME[red]},bold"
  elif (( percentage >= 100 )); then
    echo "${THEME[cyan]}"
  else
    echo "${THEME[yellow]}"
  fi
}

main() {
  local battery_status battery_percentage icon color output
  
  if is_macos; then
    read -r battery_status battery_percentage < <(get_battery_stats_macos)
  else
    read -r battery_status battery_percentage < <(get_battery_stats_linux)
  fi
  
  battery_percentage=$(validate_percentage "$battery_percentage")
  
  icon=$(get_battery_icon "$battery_status" "$battery_percentage")
  color=$(get_battery_color "$battery_percentage" "$BATTERY_LOW")
  
  output=$(format_widget_output "$color" "$icon" "$battery_percentage" "%" "$RESET")
  
  echo "$output"
}

main
