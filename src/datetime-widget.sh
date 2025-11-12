#!/usr/bin/env bash
# Verify if the current session is the minimal session
MINIMAL_SESSION_NAME=$(tmux show-option -gv @tokyo-night-tmux_minimal_session 2>/dev/null)
TMUX_SESSION_NAME=$(tmux display-message -p '#S')

if [ "$MINIMAL_SESSION_NAME" = "$TMUX_SESSION_NAME" ]; then
  exit 0
fi

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/coreutils-compat.sh"

# Check if enabled
SHOW_DATETIME=$(tmux show-option -gv @tokyo-night-tmux_show_datetime 2>/dev/null)
if [[ $SHOW_DATETIME == "0" ]]; then
  exit 0
fi

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $CURRENT_DIR/themes.sh

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# Configuration
date_format=$(tmux show-option -gv @tokyo-night-tmux_date_format 2>/dev/null)
time_format=$(tmux show-option -gv @tokyo-night-tmux_time_format 2>/dev/null)
show_timezone=$(tmux show-option -gv @tokyo-night-tmux_show_timezone 2>/dev/null)
timezone=$(tmux show-option -gv @tokyo-night-tmux_timezone 2>/dev/null)

show_timezone="${show_timezone:-0}"

date_string=""
time_string=""

# Date format
if [[ $date_format == "YMD" ]]; then
  date_string="%Y-%m-%d"
elif [[ $date_format == "MDY" ]]; then
  date_string="%m-%d-%Y"
elif [[ $date_format == "DMY" ]]; then
  date_string="%d-%m-%Y"
elif [[ $date_format == "hide" ]]; then
  date_string=""
else
  date_string="%Y-%m-%d"
fi

# Time format
if [[ $time_format == "12H" ]]; then
  time_string="%I:%M %p"
elif [[ $time_format == "hide" ]]; then
  time_string=""
else
  time_string="%H:%M"
fi

# Generate date and time
date_value="$(date +"$date_string" 2>/dev/null)"
time_value="$(date +"$time_string" 2>/dev/null)"

# Build main output with consistent format
output=""

# Calendar icon for date/time
if [[ -n "$date_value" ]] || [[ -n "$time_value" ]]; then
  icon="󰃰"
  color="#[fg=${THEME[blue]},bg=default]"
  
  # Combine date and time
  datetime=""
  if [[ -n "$date_value" ]] && [[ -n "$time_value" ]]; then
    datetime="${date_value} ${time_value}"
  elif [[ -n "$date_value" ]]; then
    datetime="${date_value}"
  elif [[ -n "$time_value" ]]; then
    datetime="${time_value}"
  fi
  
  output="${color}░ ${icon}${RESET} ${datetime}"
fi

# Add timezone support (consistent style)
if [[ $show_timezone -eq 1 ]] && [[ -n "$timezone" ]]; then
  IFS=$', ' read -ra TIMEZONES <<< "$timezone"
  
  for tz in "${TIMEZONES[@]}"; do
    [[ -z "$tz" ]] && continue
    
    # Get time in timezone
    tz_time=$(TZ="$tz" date +"%-H:%M" 2>/dev/null)
    
    if [[ -n "$tz_time" ]]; then
      # Get timezone abbreviation
      tz_abbr=$(TZ="$tz" date +"%Z" 2>/dev/null)
      # Use globe icon for timezones
      output="${output} #[fg=${THEME[cyan]},bg=default]󰥔${RESET} ${tz_abbr} ${tz_time}"
    fi
  done
fi

[[ -n "$output" ]] && echo "$output "
