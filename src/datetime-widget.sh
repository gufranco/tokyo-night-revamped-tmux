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

# Grab global variable for showing datetime widget, only hide if explicitly disabled
SHOW_DATETIME=$(tmux show-option -gv @tokyo-night-tmux_show_datetime 2>/dev/null)
if [[ $SHOW_DATETIME == "0" ]]; then
  exit 0
fi

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $CURRENT_DIR/themes.sh

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# Assign values based on user config
date_format=$(tmux show-option -gv @tokyo-night-tmux_date_format 2>/dev/null)
time_format=$(tmux show-option -gv @tokyo-night-tmux_time_format 2>/dev/null)
show_timezone=$(tmux show-option -gv @tokyo-night-tmux_show_timezone 2>/dev/null)
timezone=$(tmux show-option -gv @tokyo-night-tmux_timezone 2>/dev/null)

show_timezone="${show_timezone:-0}"

date_string=""
time_string=""

if [[ $date_format == "YMD" ]]; then
  # Year Month Day date format
  date_string="%Y-%m-%d"
elif [[ $date_format == "MDY" ]]; then
  # Month Day Year date format
  date_string="%m-%d-%Y"
elif [[ $date_format == "DMY" ]]; then
  # Day Month Year date format
  date_string="%d-%m-%Y"
elif [[ $date_format == "hide" ]]; then
  # Hide date
  date_string=""
else
  # Default to YMD date format if not specified
  date_string="%Y-%m-%d"
fi

if [[ $time_format == "12H" ]]; then
  # 12-hour format with AM/PM
  time_string="%I:%M %p"
elif [[ $time_format == "hide" ]]; then
  # Hide time
  time_string=""
else
  # Default to 24-hour format if not specified
  time_string="%H:%M"
fi

separator=""
if [[ $date_string && $time_string ]]; then
  separator="❬ "
fi

date_string="$(date +"$date_string")"
time_string="$(date +"$time_string")"

output="$RESET#[fg=${THEME[foreground]},bg=${THEME[bblack]}] $date_string $separator$time_string"

# Add timezone support
if [[ $show_timezone -eq 1 ]] && [[ -n "$timezone" ]]; then
  IFS=$', ' read -ra TIMEZONES <<< "$timezone"
  
  for tz in "${TIMEZONES[@]}"; do
    [[ -z "$tz" ]] && continue
    
    # Get time in timezone
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS: use TZ environment variable
      tz_time=$(TZ="$tz" date +"%-H:%M" 2>/dev/null)
    else
      # Linux: use TZ environment variable  
      tz_time=$(TZ="$tz" date +"%-H:%M" 2>/dev/null)
    fi
    
    if [[ -n "$tz_time" ]]; then
      # Get timezone abbreviation
      tz_abbr=$(TZ="$tz" date +"%Z" 2>/dev/null)
      output="${output}$RESET#[fg=${THEME[blue]},bg=${THEME[bblack]}] 󰥔 ${tz_abbr} ${tz_time}"
    fi
  done
fi

echo "$output "
