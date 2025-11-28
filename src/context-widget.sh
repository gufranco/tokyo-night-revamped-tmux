#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/widget/widget-loader.sh"
source "${LIB_DIR}/tmux/tmux-ops.sh"
source "${LIB_DIR}/widget/widget-common.sh"
source "${LIB_DIR}/widget/widget-config.sh"

load_widget_dependencies "context"

validate_minimal_session
validate_widget_enabled "@yoru_show_context"

SHOW_WEATHER=$(is_widget_feature_enabled "@yoru_context_weather" "1")
WEATHER_UNITS=$(get_tmux_option "@yoru_context_weather_units" "m")
DATE_FORMAT=$(get_tmux_option "@yoru_context_date_format" "YMD")
TIME_FORMAT=$(get_tmux_option "@yoru_context_time_format" "24H")
SHOW_TIMEZONE=$(is_widget_feature_enabled "@yoru_context_timezone" "0")
TIMEZONES=$(get_tmux_option "@yoru_context_timezones" "")

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

main() {
  local OUTPUT
  OUTPUT=""

  if [[ $SHOW_WEATHER -eq 1 ]]; then
    local WEATHER_CACHE weather_data cache_time current_time cache_age weather_url weather_display
    WEATHER_CACHE="/tmp/tmux_yoru_weather_cache"
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
      weather_display=$(get_temperature_color_and_icon "$weather_data")
      OUTPUT="${weather_display} ${weather_data}${COLOR_RESET}"
    fi
  fi

  local DATE_STR TIME_STR DATE_VAL TIME_VAL DATETIME
  DATE_STR=$(get_date_format "$DATE_FORMAT")
  TIME_STR=$(get_time_format "$TIME_FORMAT")

  if [[ -n "$DATE_STR" ]]; then
    DATE_VAL=$(date +"$DATE_STR" 2>/dev/null)
  fi

  if [[ -n "$TIME_STR" ]]; then
    TIME_VAL=$(date +"$TIME_STR" 2>/dev/null)
  fi

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
    OUTPUT="${OUTPUT}${COLOR_CYAN}󰥔 ${DATETIME}${COLOR_RESET}"
  fi

  if [[ "$SHOW_TIMEZONE" == "1" ]] && [[ -n "$TIMEZONES" ]]; then
    local TZ_LIST tz tz_hour tz_time tz_abbr tz_dow is_weekend period_icon period_color
    IFS=$', ' read -ra TZ_LIST <<< "$TIMEZONES"

    for tz in "${TZ_LIST[@]}"; do
      [[ -z "$tz" ]] && continue

      read -r tz_hour tz_time tz_abbr tz_dow < <(TZ="$tz" date +"%-H %H:%M %Z %u" 2>/dev/null) || continue

      is_weekend=0
      [[ $tz_dow -eq 6 ]] || [[ $tz_dow -eq 7 ]] && is_weekend=1

      period_icon=$(get_timezone_period_icon "$tz_hour" "$is_weekend")
      period_color=$(get_timezone_period_color "$tz_hour" "$is_weekend")

      OUTPUT="${OUTPUT} ${COLOR_CYAN}󰥔${COLOR_RESET} ${period_color}${tz_abbr} ${period_icon} ${tz_time}${COLOR_RESET}"
    done
  fi

  local tooltip_text
  tooltip_text=$(generate_context_tooltip)
  set_widget_tooltip "context" "$tooltip_text"

  [[ -n "$OUTPUT" ]] && echo "${COLOR_CYAN}░${COLOR_RESET} ${OUTPUT}"
}

main

