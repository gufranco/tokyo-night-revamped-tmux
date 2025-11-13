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

SHOW_DATETIME=$(tmux show-option -gv @tokyo-night-tmux_show_datetime 2>/dev/null)
[[ "$SHOW_DATETIME" == "0" ]] && exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"
CYAN="#[fg=${THEME[cyan]},bg=default]"

DATE_FORMAT=$(tmux show-option -gv @tokyo-night-tmux_date_format 2>/dev/null)
TIME_FORMAT=$(tmux show-option -gv @tokyo-night-tmux_time_format 2>/dev/null)
SHOW_TIMEZONE=$(tmux show-option -gv @tokyo-night-tmux_show_timezone 2>/dev/null)
TIMEZONES=$(tmux show-option -gv @tokyo-night-tmux_timezone 2>/dev/null)

DATE_FORMAT="${DATE_FORMAT:-YMD}"
TIME_FORMAT="${TIME_FORMAT:-24H}"
SHOW_TIMEZONE="${SHOW_TIMEZONE:-0}"

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

[[ -z "$DATETIME" ]] && exit 0

OUTPUT="${CYAN}░ 󰥔${RESET} ${DATETIME}"

if [[ "$SHOW_TIMEZONE" == "1" ]] && [[ -n "$TIMEZONES" ]]; then
  IFS=$', ' read -ra TZ_LIST <<< "$TIMEZONES"
  
  for tz in "${TZ_LIST[@]}"; do
    [[ -z "$tz" ]] && continue
    
    tz_time=$(TZ="$tz" date +"%-H:%M" 2>/dev/null) || continue
    tz_abbr=$(TZ="$tz" date +"%Z" 2>/dev/null) || continue
    
    OUTPUT="${OUTPUT} ${CYAN}󰥔${RESET} ${tz_abbr} ${tz_time}"
  done
fi

echo "${OUTPUT} "
