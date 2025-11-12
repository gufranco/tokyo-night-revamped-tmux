#!/usr/bin/env bash

# Check if enabled
ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_weather 2>/dev/null)
[[ ${ENABLED} -ne 1 ]] && exit 0

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/../lib/coreutils-compat.sh"
source "$CURRENT_DIR/../lib/system.sh"
source "$CURRENT_DIR/themes.sh"

if ! check_any_command "curl" "wget"; then
  echo "#[fg=${THEME[yellow]}]⚠ Weather requires 'curl' or 'wget' "
  exit 0
fi

UNITS=$(tmux show-option -gv @tokyo-night-tmux_weather_units 2>/dev/null)
EXTRA_LOCATIONS=$(tmux show-option -gv @tokyo-night-tmux_weather_location 2>/dev/null)
SHOW_ICON=$(tmux show-option -gv @tokyo-night-tmux_weather_show_icon 2>/dev/null)

UNITS="${UNITS:-m}"
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

# Fetch weather data with city name
get_weather_data() {
  local location="$1"
  # Format: %l=location, %t=temperature
  local weather_url="https://wttr.in/${location}?format=%l:+%t&${UNITS}"
  
  if command -v curl >/dev/null 2>&1; then
    curl -sf "$weather_url" 2>/dev/null
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$weather_url" 2>/dev/null
  fi
}

# Get color and icon based on temperature
get_temp_style() {
  local temp="$1"
  local color icon
  
  if (( temp >= 30 )); then
    color="${THEME[red]}"
    icon="󰖙"  # Sun hot
  elif (( temp >= 20 )); then
    color="${THEME[yellow]}"
    icon="󰖙"  # Sun
  elif (( temp >= 10 )); then
    color="${THEME[cyan]}"
    icon="󰖐"  # Cloud sun
  elif (( temp >= 0 )); then
    color="${THEME[blue]}"
    icon="󰖐"  # Cloud
  else
    color="${THEME[magenta]}"
    icon="󰜗"  # Snowflake
  fi
  
  [[ "$SHOW_ICON" != "1" ]] && icon=""
  
  echo "$color|$icon"
}

# Format weather output
format_weather() {
  local data="$1"
  local is_first="$2"
  
  # Parse: "City Name: +24°C" → extract city and temp
  local city=$(echo "$data" | cut -d':' -f1 | xargs)
  local temp_str=$(echo "$data" | cut -d':' -f2 | xargs)
  local temp=$(echo "$temp_str" | grep -oE '[+-]?[0-9]+' | head -1)
  
  if [[ -z "$temp" ]]; then
    return
  fi
  
  IFS='|' read -r color icon <<< "$(get_temp_style "$temp")"
  
  # Shorten city name if too long
  if [[ ${#city} -gt 15 ]]; then
    city="${city:0:12}..."
  fi
  
  if [[ "$is_first" == "1" ]]; then
    # First location (with separator)
    if [[ -n "$icon" ]]; then
      echo "#[fg=${color},bg=default]░ ${icon}${RESET} ${city} ${temp_str}"
    else
      echo "#[fg=${color},bg=default]░${RESET} ${city} ${temp_str}"
    fi
  else
    # Additional locations (no separator)
    if [[ -n "$icon" ]]; then
      echo " #[fg=${color},bg=default]${icon}${RESET} ${city} ${temp_str}"
    else
      echo " #[fg=${color},bg=default]${RESET}${city} ${temp_str}"
    fi
  fi
}

OUTPUT=""
is_first=1

# Always show current location first
CURRENT_WEATHER=$(get_weather_data "")

if [[ -n "$CURRENT_WEATHER" ]]; then
  OUTPUT="$(format_weather "$CURRENT_WEATHER" "$is_first")"
  is_first=0
fi

# Add extra locations if configured
if [[ -n "$EXTRA_LOCATIONS" ]]; then
  # Support comma or space-separated
  IFS=$', ' read -ra LOCATION_LIST <<< "$EXTRA_LOCATIONS"
  
  for location in "${LOCATION_LIST[@]}"; do
    location=$(echo "$location" | xargs)
    [[ -z "$location" ]] && continue
    
    # Replace underscores with spaces for API
    location_api="${location//_/ }"
    
    WEATHER_DATA=$(get_weather_data "$location_api")
    
    if [[ -n "$WEATHER_DATA" ]]; then
      location_output="$(format_weather "$WEATHER_DATA" "$is_first")"
      if [[ -n "$location_output" ]]; then
        OUTPUT="${OUTPUT}${location_output}"
        is_first=0
      fi
    fi
  done
fi

if [[ -n "$OUTPUT" ]]; then
  OUTPUT="${OUTPUT} "
  echo "$OUTPUT" > "$CACHE_FILE"
  echo "$OUTPUT"
fi
