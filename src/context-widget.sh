#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${LIB_DIR}/themes.sh"
source "${LIB_DIR}/color-scale.sh"
source "${LIB_DIR}/format.sh"
source "${LIB_DIR}/error-logger.sh"
source "${LIB_DIR}/tooltip.sh"

MINIMAL_SESSION=$(tmux show-option -gv @tokyo-night-tmux_minimal_session 2>/dev/null)
CURRENT_SESSION=$(tmux display-message -p '#S')

[[ -n "$MINIMAL_SESSION" ]] && [[ "$MINIMAL_SESSION" == "$CURRENT_SESSION" ]] && exit 0

SHOW_CONTEXT=$(tmux show-option -gv @tokyo-night-tmux_show_context 2>/dev/null)
[[ "$SHOW_CONTEXT" == "0" ]] && exit 0

SHOW_WEATHER=$(tmux show-option -gv @tokyo-night-tmux_context_weather 2>/dev/null)
WEATHER_UNITS=$(tmux show-option -gv @tokyo-night-tmux_context_weather_units 2>/dev/null)
DATE_FORMAT=$(tmux show-option -gv @tokyo-night-tmux_context_date_format 2>/dev/null)
TIME_FORMAT=$(tmux show-option -gv @tokyo-night-tmux_context_time_format 2>/dev/null)
SHOW_TIMEZONE=$(tmux show-option -gv @tokyo-night-tmux_context_timezone 2>/dev/null)
TIMEZONES=$(tmux show-option -gv @tokyo-night-tmux_context_timezones 2>/dev/null)
SHOW_MUSIC=$(tmux show-option -gv @tokyo-night-tmux_context_music 2>/dev/null)

SHOW_WEATHER="${SHOW_WEATHER:-1}"
WEATHER_UNITS="${WEATHER_UNITS:-m}"
DATE_FORMAT="${DATE_FORMAT:-YMD}"
TIME_FORMAT="${TIME_FORMAT:-24H}"
SHOW_TIMEZONE="${SHOW_TIMEZONE:-0}"
SHOW_MUSIC="${SHOW_MUSIC:-0}"

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
    weather_display=$(get_temperature_color_and_icon "$weather_data")
    OUTPUT="${weather_display} ${weather_data}${COLOR_RESET}"
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

if [[ $SHOW_SSH -eq 1 ]]; then
  if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]] || [[ -n "$SSH_CONNECTION" ]]; then
    local ssh_host
    ssh_host="${SSH_CLIENT%% *}"
    if [[ -z "$ssh_host" ]]; then
      ssh_host=$(hostname 2>/dev/null || echo "remote")
    fi
    [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}${COLOR_CYAN}${ICON_SSH} ${ssh_host}${COLOR_RESET}"
  fi
fi

if [[ $SHOW_PATH -eq 1 ]]; then
  local current_path
  current_path="${PWD/#$HOME/~}"
  if [[ ${#current_path} -gt 30 ]]; then
    current_path="...${current_path: -27}"
  fi
  [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
  OUTPUT="${OUTPUT}${COLOR_CYAN}${ICON_PATH} ${current_path}${COLOR_RESET}"
fi

if [[ $SHOW_SESSION -eq 1 ]]; then
  local session_name
  session_name=$(tmux display-message -p '#S' 2>/dev/null)
  if [[ -n "$session_name" ]]; then
    [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}${COLOR_CYAN}󰆍 ${session_name}${COLOR_RESET}"
  fi
fi

if [[ $SHOW_MUSIC -eq 1 ]]; then
  local music_status
  music_status=$(get_music_player_status)
  if [[ -n "$music_status" ]]; then
    IFS='|' read -r status artist title <<< "$music_status"
    if [[ -n "$title" ]]; then
      title="${title:0:20}"
      [[ -n "$artist" ]] && title="${artist:0:10} - ${title}"
      local music_icon
      [[ "$status" == "Playing" ]] && music_icon="${ICON_MUSIC_PLAY}" || music_icon="${ICON_MUSIC_PAUSE}"
      [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
      OUTPUT="${OUTPUT}${COLOR_CYAN}${music_icon} ${title}${COLOR_RESET}"
    fi
  fi
fi

if [[ $SHOW_UPDATES -eq 1 ]]; then
  local updates
  updates=$(get_system_updates)
  if [[ -n "$updates" ]] && [[ "$updates" =~ ^[0-9]+$ ]] && [[ $updates -gt 0 ]]; then
    local update_color
    if (( updates >= 10 )); then
      update_color="${COLOR_RED}"
    elif (( updates >= 5 )); then
      update_color="${COLOR_YELLOW}"
    else
      update_color="${COLOR_CYAN}"
    fi
    [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}${update_color}${ICON_UPDATES} ${updates}${COLOR_RESET}"
  fi
fi

if [[ $SHOW_BLUETOOTH -eq 1 ]]; then
  local bluetooth_status
  bluetooth_status=$(get_bluetooth_status)
  if [[ -n "$bluetooth_status" ]]; then
    IFS='|' read -r status devices <<< "$bluetooth_status"
    if [[ "$status" == "1" ]] || [[ "$status" == "on" ]]; then
      [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
      if [[ -n "$devices" ]] && [[ "$devices" =~ ^[0-9]+$ ]] && [[ $devices -gt 0 ]]; then
        OUTPUT="${OUTPUT}${COLOR_CYAN}${ICON_BLUETOOTH} ${devices}${COLOR_RESET}"
      else
        OUTPUT="${OUTPUT}${COLOR_CYAN}${ICON_BLUETOOTH}${COLOR_RESET}"
      fi
    fi
  fi
fi

if [[ $SHOW_AUDIO -eq 1 ]]; then
  local audio_device
  audio_device=$(get_audio_device)
  if [[ -n "$audio_device" ]]; then
    audio_device="${audio_device:0:15}"
    [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}${COLOR_CYAN}${ICON_AUDIO} ${audio_device}${COLOR_RESET}"
  fi
fi

if [[ $SHOW_BRIGHTNESS -eq 1 ]]; then
  local brightness
  brightness=$(get_screen_brightness)
  if [[ -n "$brightness" ]] && [[ "$brightness" =~ ^[0-9]+$ ]] && [[ $brightness -gt 0 ]]; then
    [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}${COLOR_CYAN}${ICON_BRIGHTNESS} ${brightness}%${COLOR_RESET}"
  fi
fi

local tooltip_text
tooltip_text=$(generate_context_tooltip)
set_widget_tooltip "context" "$tooltip_text"

[[ -n "$OUTPUT" ]] && echo "${COLOR_CYAN}░${COLOR_RESET} ${OUTPUT}"

