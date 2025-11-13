#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${SCRIPT_DIR}/themes.sh"

is_widget_enabled "@tokyo-night-tmux_show_weather" || exit 0

command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || exit 0

UNITS=$(tmux show-option -gv @tokyo-night-tmux_weather_units 2>/dev/null)
UNITS="${UNITS:-m}"

CACHE_FILE="/tmp/tmux_tokyo_night_weather_cache"

check_cache_valid() {
  [[ ! -f "$CACHE_FILE" ]] && return 1
  
  local cache_time current_time cache_age
  
  if is_macos; then
    cache_time=$(stat -f "%m" "$CACHE_FILE" 2>/dev/null)
  else
    cache_time=$(stat -c "%Y" "$CACHE_FILE" 2>/dev/null)
  fi
  
  [[ ! "$cache_time" =~ ^[0-9]+$ ]] && return 1
  
  current_time=$(date +%s)
  cache_age=$((current_time - cache_time))
  
  (( cache_age < WEATHER_CACHE_TTL ))
}

if check_cache_valid; then
  cat "$CACHE_FILE"
  exit 0
fi

WEATHER_URL="https://wttr.in/?format=%t&${UNITS}"

if command -v curl >/dev/null 2>&1; then
  WEATHER_DATA=$(curl -sf "$WEATHER_URL" 2>/dev/null)
elif command -v wget >/dev/null 2>&1; then
  WEATHER_DATA=$(wget -qO- "$WEATHER_URL" 2>/dev/null)
fi

[[ -z "$WEATHER_DATA" ]] && exit 0

TEMP=$(echo "$WEATHER_DATA" | grep -oE '[+-]?[0-9]+' | head -1)

[[ -z "$TEMP" ]] && exit 0

if (( TEMP >= 30 )); then
  ICON="󰖙"
elif (( TEMP >= 20 )); then
  ICON="󰖙"
elif (( TEMP >= 10 )); then
  ICON="󰖐"
elif (( TEMP >= 0 )); then
  ICON="󰖐"
else
  ICON="󰜗"
fi

OUTPUT="#[fg=${THEME[cyan]},bg=default]░ ${ICON}${RESET} ${WEATHER_DATA} "

echo "$OUTPUT" | tee "$CACHE_FILE"
