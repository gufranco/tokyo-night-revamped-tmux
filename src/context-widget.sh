#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${LIB_DIR}/themes.sh"

MINIMAL_SESSION=$(tmux show-option -gv @tokyo-night-tmux_minimal_session 2>/dev/null)
CURRENT_SESSION=$(tmux display-message -p '#S')

[[ -n "$MINIMAL_SESSION" ]] && [[ "$MINIMAL_SESSION" == "$CURRENT_SESSION" ]] && exit 0

SHOW_CONTEXT=$(tmux show-option -gv @tokyo-night-tmux_show_context 2>/dev/null)
[[ "$SHOW_CONTEXT" == "0" ]] && exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"
CYAN="#[fg=${THEME[cyan]},bg=default]"

SHOW_WEATHER=$(tmux show-option -gv @tokyo-night-tmux_context_weather 2>/dev/null)
WEATHER_UNITS=$(tmux show-option -gv @tokyo-night-tmux_context_weather_units 2>/dev/null)
DATE_FORMAT=$(tmux show-option -gv @tokyo-night-tmux_context_date_format 2>/dev/null)
TIME_FORMAT=$(tmux show-option -gv @tokyo-night-tmux_context_time_format 2>/dev/null)
SHOW_TIMEZONE=$(tmux show-option -gv @tokyo-night-tmux_context_timezone 2>/dev/null)
TIMEZONES=$(tmux show-option -gv @tokyo-night-tmux_context_timezones 2>/dev/null)

SHOW_WEATHER="${SHOW_WEATHER:-1}"
WEATHER_UNITS="${WEATHER_UNITS:-m}"
DATE_FORMAT="${DATE_FORMAT:-YMD}"
TIME_FORMAT="${TIME_FORMAT:-24H}"
SHOW_TIMEZONE="${SHOW_TIMEZONE:-0}"

OUTPUT=""

if [[ $SHOW_WEATHER -eq 1 ]]; then
  WEATHER_CACHE="/tmp/tmux_tokyo_night_weather_cache"
  weather_data=""
  
  if [[ -f "$WEATHER_CACHE" ]]; then
    cache_time=""
    
    if is_macos; then
      cache_time=$(stat -f "%m" "$WEATHER_CACHE" 2>/dev/null)
    else
      cache_time=$(stat -c "%Y" "$WEATHER_CACHE" 2>/dev/null)
    fi
    
    if [[ -n "$cache_time" ]] && [[ "$cache_time" =~ ^[0-9]+$ ]]; then
      current_time=$(date +%s)
      cache_age=$((current_time - cache_time))
      
      if (( cache_age < WEATHER_CACHE_TTL )); then
        weather_data=$(cat "$WEATHER_CACHE")
      fi
    fi
  fi
  
  if [[ -z "$weather_data" ]]; then
    if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
      weather_url="https://wttr.in/?format=%t&${WEATHER_UNITS}"
      
      if command -v curl >/dev/null 2>&1; then
        weather_data=$(curl -sf "$weather_url" 2>/dev/null)
      elif command -v wget >/dev/null 2>&1; then
        weather_data=$(wget -qO- "$weather_url" 2>/dev/null)
      fi
      
      [[ -n "$weather_data" ]] && echo "$weather_data" > "$WEATHER_CACHE"
    fi
  fi
  
  if [[ -n "$weather_data" ]]; then
    OUTPUT="${CYAN}󰖙${RESET} ${weather_data}"
  fi
fi

get_date_format() {
  case "${1}" in
    YMD) echo "%Y-%m-%d" ;;
    MDY) echo "%m-%d-%Y" ;;
    DMY) echo "%d-%m-%Y" ;;
    hide) echo "" ;;
    *) echo "%Y-%m-%d" ;;
  esac
}

get_time_format() {
  case "${1}" in
    12H) echo "%I:%M %p" ;;
    hide) echo "" ;;
    *) echo "%H:%M" ;;
  esac
}

DATE_STR=$(get_date_format "$DATE_FORMAT")
TIME_STR=$(get_time_format "$TIME_FORMAT")

DATE_VAL=$(date +"$DATE_STR" 2>/dev/null)
TIME_VAL=$(date +"$TIME_STR" 2>/dev/null)

DATETIME=""
if [[ -n "$DATE_VAL" ]] && [[ -n "$TIME_VAL" ]]; then
  DATETIME="${DATE_VAL} ${TIME_VAL}"
elif [[ -n "$DATE_VAL" ]]; then
  DATETIME="${DATE_VAL}"
elif [[ -n "$TIME_VAL" ]]; then
  DATETIME="${TIME_VAL}"
fi

if [[ -n "$DATETIME" ]]; then
  [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
  OUTPUT="${OUTPUT}${CYAN}󰥔${RESET} ${DATETIME}"
fi

if [[ "$SHOW_TIMEZONE" == "1" ]] && [[ -n "$TIMEZONES" ]]; then
  IFS=$', ' read -ra TZ_LIST <<< "$TIMEZONES"
  
  for tz in "${TZ_LIST[@]}"; do
    [[ -z "$tz" ]] && continue
    
    tz_time=$(TZ="$tz" date +"%-H:%M" 2>/dev/null) || continue
    tz_abbr=$(TZ="$tz" date +"%Z" 2>/dev/null) || continue
    
    OUTPUT="${OUTPUT} ${CYAN}󰥔${RESET} ${tz_abbr} ${tz_time}"
  done
fi

[[ -n "$OUTPUT" ]] && echo "${CYAN}░${RESET} ${OUTPUT} "

