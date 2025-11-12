#!/usr/bin/env bash

# Check if enabled
ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_weather 2>/dev/null)
[[ ${ENABLED} -ne 1 ]] && exit 0

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/../lib/coreutils-compat.sh"
source "$CURRENT_DIR/../lib/system.sh"
source "$CURRENT_DIR/themes.sh"

if ! check_any_command "curl" "wget"; then
  echo "#[fg=${THEME[yellow]}]⚠ Weather widget requires 'curl' or 'wget'. Install: brew install curl "
  exit 0
fi

UNITS=$(tmux show-option -gv @tokyo-night-tmux_weather_units 2>/dev/null)
LOCATION=$(tmux show-option -gv @tokyo-night-tmux_weather_location 2>/dev/null)
FORMAT=$(tmux show-option -gv @tokyo-night-tmux_weather_format 2>/dev/null)
SHOW_ICON=$(tmux show-option -gv @tokyo-night-tmux_weather_show_icon 2>/dev/null)

UNITS="${UNITS:-m}"
FORMAT="${FORMAT:-%t}"
SHOW_ICON="${SHOW_ICON:-1}"

# Cache configuration (15 minutes)
CACHE_FILE="/tmp/tmux_tokyo_night_weather_cache"
CACHE_TTL=900

# Check cache
if [[ -f "$CACHE_FILE" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    cache_time=$(stat -f "%m" "$CACHE_FILE" 2>/dev/null)
  else
    cache_time=$(stat -c "%Y" "$CACHE_FILE" 2>/dev/null)
  fi
  current_time=$(date +%s)
  
  if [[ -n "$cache_time" ]] && [[ "$cache_time" =~ ^[0-9]+$ ]]; then
    cache_age=$((current_time - cache_time))
    
    if [[ $cache_age -lt $CACHE_TTL ]]; then
      cat "$CACHE_FILE"
      exit 0
    fi
  fi
fi

# Fetch weather data
WEATHER_URL="https://wttr.in/${LOCATION}?format=${FORMAT}&${UNITS}"

if command -v curl >/dev/null 2>&1; then
  WEATHER_DATA=$(curl -sf "$WEATHER_URL" 2>/dev/null)
elif command -v wget >/dev/null 2>&1; then
  WEATHER_DATA=$(wget -qO- "$WEATHER_URL" 2>/dev/null)
fi

if [[ -z "$WEATHER_DATA" ]]; then
  exit 0
fi

# Extract temperature for color coding
TEMP=$(echo "$WEATHER_DATA" | grep -oE '[+-]?[0-9]+' | head -1)

if [[ -n "$TEMP" ]]; then
  if (( TEMP >= 30 )); then
    COLOR="${THEME[red]}"
  elif (( TEMP >= 20 )); then
    COLOR="${THEME[yellow]}"
  elif (( TEMP >= 10 )); then
    COLOR="${THEME[cyan]}"
  elif (( TEMP >= 0 )); then
    COLOR="${THEME[blue]}"
  else
    COLOR="${THEME[magenta]}"
  fi
  
  ICON=""
  if [[ "$SHOW_ICON" == "1" ]]; then
    ICON=" "
  fi
  
  # Build output (consistent format: separator + icon + value)
  OUTPUT="#[fg=${COLOR},bg=default]░${ICON} ${WEATHER_DATA} "
  
  # Cache the result
  echo "$OUTPUT" > "$CACHE_FILE"
  echo "$OUTPUT"
fi

