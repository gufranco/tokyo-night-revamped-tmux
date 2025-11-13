#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${LIB_DIR}/music-helpers.sh"
source "${SCRIPT_DIR}/themes.sh"

MINIMAL_SESSION=$(tmux show-option -gv @tokyo-night-tmux_minimal_session 2>/dev/null)
CURRENT_SESSION=$(tmux display-message -p '#S')

[[ -n "$MINIMAL_SESSION" ]] && [[ "$MINIMAL_SESSION" == "$CURRENT_SESSION" ]] && exit 0

SHOW_MUSIC=$(tmux show-option -gv @tokyo-night-tmux_show_music 2>/dev/null)
[[ "$SHOW_MUSIC" != "1" ]] && exit 0

ACCENT_COLOR="${THEME[blue]}"
BG_COLOR="${THEME[background]}"
TIME_COLOR="${THEME[black]}"

MAX_TITLE_WIDTH=25
if [[ $1 =~ ^[[:digit:]]+$ ]]; then
  MAX_TITLE_WIDTH=$1
else
  MAX_TITLE_WIDTH=$(($(tmux display -p '#{window_width}' 2>/dev/null || echo 120) - 90))
fi

get_music_metadata() {
  local metadata
  
  if metadata=$(get_playerctl_metadata); then
    parse_playerctl "$metadata"
    return 0
  fi
  
  if metadata=$(get_mediacontrol_metadata); then
    parse_mediacontrol "$metadata"
    return 0
  fi
  
  return 1
}

format_play_state() {
  local status="${1}"
  
  if [[ "$status" == "playing" ]]; then
    echo "░ ${ICON_MUSIC_PLAY}"
  else
    echo "░ ${ICON_MUSIC_PAUSE}"
  fi
}

truncate_title() {
  local title="${1}"
  local max_width="${2}"
  local play_state="${3}"
  
  local output="${play_state} ${title}"
  
  if (( ${#output} >= max_width )); then
    output="${play_state} ${title:0:$((max_width - 1))}…"
  fi
  
  echo "$output"
}

build_progress_bar() {
  local title="${1}"
  local time="${2}"
  local position="${3}"
  local duration="${4}"
  
  local output="${title} ${time} "
  local only_out="${title} "
  local time_index=${#only_out}
  local output_length=${#output}
  local percent=$((position * 100 / duration))
  local progress=$((output_length * percent / 100))
  
  if (( progress <= time_index )); then
    echo "#[nobold,fg=$BG_COLOR,bg=$ACCENT_COLOR]${title:0:progress}#[fg=$ACCENT_COLOR,bg=$BG_COLOR]${title:progress:time_index} #[fg=$TIME_COLOR,bg=$BG_COLOR]$time "
  else
    local diff=$((progress - time_index))
    echo "#[nobold,fg=$BG_COLOR,bg=$ACCENT_COLOR]${title:0:time_index} #[fg=$BG_COLOR,bg=$ACCENT_COLOR]${output:time_index:diff}#[fg=$TIME_COLOR,bg=$BG_COLOR]${output:progress}"
  fi
}

main() {
  local status title duration position
  
  IFS='|' read -r status title duration position <<< "$(get_music_metadata)" || exit 0
  
  [[ -z "$title" ]] && exit 0
  
  check_pause_timeout "$status" && exit 0
  
  local play_state output
  play_state=$(format_play_state "$status")
  output=$(truncate_title "$title" "$MAX_TITLE_WIDTH" "$play_state")
  
  if should_show_time "$duration"; then
    local time
    time="[$(format_time "$position") / $(format_time "$duration")]"
    build_progress_bar "$output" "$time" "$position" "$duration"
  else
    echo "${play_state} ${title} "
  fi
}

main
