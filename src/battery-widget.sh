#!/usr/bin/env bash

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/coreutils-compat.sh"

# Check if the battery widget is enabled
SHOW_BATTERY_WIDGET=$(tmux show-option -gv @tokyo-night-tmux_show_battery_widget 2>/dev/null)
if [ "${SHOW_BATTERY_WIDGET}" != "1" ]; then
  exit 0
fi

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/themes.sh"

# Get values from tmux config or set defaults
BATTERY_NAME=$(tmux show-option -gv @tokyo-night-tmux_battery_name 2>/dev/null)
BATTERY_LOW=$(tmux show-option -gv @tokyo-night-tmux_battery_low_threshold 2>/dev/null)
RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# Icons
DISCHARGING_ICONS=("󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
CHARGING_ICONS=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
AC_POWER_ICON="󰚥"
NO_BATTERY_ICON="󱉝"
DEFAULT_BATTERY_LOW=21

# Platform-specific defaults
if [[ "$(uname)" == "Darwin" ]]; then
  default_battery_name="InternalBattery-0"
else
  default_battery_name="BAT1"
fi

BATTERY_NAME="${BATTERY_NAME:-$default_battery_name}"
BATTERY_LOW="${BATTERY_LOW:-$DEFAULT_BATTERY_LOW}"

# Check if battery exists
battery_exists() {
  case "$(uname)" in
  "Darwin")
    pmset -g batt | grep -q "$BATTERY_NAME"
    ;;
  "Linux")
    [[ -d "/sys/class/power_supply/$BATTERY_NAME" ]]
    ;;
  *)
    return 1
    ;;
  esac
}

# Exit early if no battery found
if ! battery_exists; then
  exit 0
fi

# Get battery stats for different OS
get_battery_stats() {
  local battery_name=$1
  local battery_status=""
  local battery_percentage=""
  local ac_power=""

  case "$(uname)" in
  "Darwin")
    ac_power=$(pmset -g batt | head -1 | grep -i "AC Power")
    pmstat=$(pmset -g batt | grep "$battery_name")
    battery_status=$(echo "$pmstat" | awk '{print $4}' | sed 's/[^a-zA-Z]*//g')
    battery_percentage=$(echo "$pmstat" | awk '{print $3}' | sed 's/[^0-9]*//g')

    # If on AC power, mark as charging
    if [[ -n "$ac_power" ]]; then
      battery_status="charging"
    fi
    ;;
  "Linux")
    if [[ -f "/sys/class/power_supply/${battery_name}/status" && -f "/sys/class/power_supply/${battery_name}/capacity" ]]; then
      battery_status=$(<"/sys/class/power_supply/${battery_name}/status")
      battery_percentage=$(<"/sys/class/power_supply/${battery_name}/capacity")

      # Check if AC adapter is connected
      for adapter in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        if [[ -f "$adapter" ]]; then
          if [[ $(<"$adapter") -eq 1 ]]; then
            battery_status="charging"
            break
          fi
        fi
      done
    else
      battery_status="Unknown"
      battery_percentage="0"
    fi
    ;;
  *)
    battery_status="Unknown"
    battery_percentage="0"
    ;;
  esac
  echo "$battery_status $battery_percentage"
}

# Fetch the battery status and percentage
read -r BATTERY_STATUS BATTERY_PERCENTAGE < <(get_battery_stats "$BATTERY_NAME")

# Ensure percentage is a number
if ! [[ $BATTERY_PERCENTAGE =~ ^[0-9]+$ ]]; then
  BATTERY_PERCENTAGE=0
fi

# Calculate icon index
icon_idx=$(( BATTERY_PERCENTAGE / 10 ))
if [[ $icon_idx -gt 10 ]]; then
  icon_idx=10
elif [[ $icon_idx -lt 0 ]]; then
  icon_idx=0
fi

# Determine icon based on battery status
BATTERY_STATUS_LOWER=$(echo "$BATTERY_STATUS" | tr '[:upper:]' '[:lower:]')

# Logic: Plugged in (AC) = plug icon, On battery = battery icons by level
case "${BATTERY_STATUS_LOWER}" in
charging|charged|full|ac)
  # Plugged into AC power - show plug icon
  ICON="${AC_POWER_ICON}"
  ;;
discharging)
  # Running on battery - show battery level icon
  ICON="${DISCHARGING_ICONS[$icon_idx]}"
  ;;
*)
  ICON="${NO_BATTERY_ICON}"
  ;;
esac

ICON="${ICON:-$NO_BATTERY_ICON}"

# Set color based on battery percentage (matches iStats)
if [[ $BATTERY_PERCENTAGE -lt $BATTERY_LOW ]]; then
  color="#[fg=${THEME[red]},bg=default,bold]"  # Red - critical
elif [[ $BATTERY_PERCENTAGE -ge 100 ]]; then
  color="#[fg=${THEME[cyan]},bg=default]"  # Cyan - fully charged
else
  color="#[fg=${THEME[yellow]},bg=default]"  # Yellow - normal
fi

# Build output (consistent format: separator + icon + value)
echo "${color}░ ${ICON}${RESET} ${BATTERY_PERCENTAGE}% "
