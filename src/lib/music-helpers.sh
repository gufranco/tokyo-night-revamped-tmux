#!/usr/bin/env bash

PAUSE_TIMEOUT=30
PAUSE_STATE_FILE="/tmp/tmux_tokyo_night_music_pause_state"

get_playerctl_metadata() {
  command -v playerctl >/dev/null 2>&1 || return 1
  
  local format="{{status}};{{mpris:length}};{{position}};{{title}}"
  local player_status
  
  player_status=$(playerctl -a metadata --format "$format" 2>/dev/null | grep -m1 "Playing")
  
  if [[ -z "$player_status" ]]; then
    player_status=$(playerctl -a metadata --format "$format" 2>/dev/null | grep -m1 "Paused")
  fi
  
  [[ -z "$player_status" ]] && return 1
  
  echo "$player_status"
}

get_mediacontrol_metadata() {
  command -v media-control >/dev/null 2>&1 || return 1
  [[ "$OSTYPE" != "darwin"* ]] && return 1
  
  local media_json
  media_json=$(media-control get --now 2>/dev/null) || return 1
  
  [[ -z "$media_json" ]] && return 1
  
  echo "$media_json"
}

parse_playerctl() {
  local data="${1}"
  
  local status title duration position
  status=$(echo "$data" | cut -d';' -f1 | tr '[:upper:]' '[:lower:]')
  duration=$(echo "$data" | cut -d';' -f2)
  position=$(echo "$data" | cut -d';' -f3)
  title=$(echo "$data" | cut -d';' -f4)
  
  duration=$((duration / 1000000))
  position=$((position / 1000000))
  
  [[ $duration -eq 0 ]] && duration=-1 && position=0
  
  echo "$status|$title|$duration|$position"
}

parse_mediacontrol() {
  local json="${1}"
  
  local playback_rate title duration position status
  
  playback_rate=$(echo "$json" | grep -o '"playbackRate":[0-9]*' | cut -d':' -f2)
  title=$(echo "$json" | grep -o '"title":"[^"]*"' | sed 's|"title":"||' | sed 's|"$||')
  duration=$(echo "$json" | grep -o '"duration":[0-9.]*' | cut -d':' -f2 | cut -d'.' -f1)
  position=$(echo "$json" | grep -o '"elapsedTime":[0-9.]*' | cut -d':' -f2 | cut -d'.' -f1)
  
  if [[ "$playback_rate" -gt 0 ]] 2>/dev/null; then
    status="playing"
  else
    status="paused"
  fi
  
  [[ -z "$duration" ]] || [[ $duration -eq 0 ]] && duration=-1 && position=0
  
  if [[ $duration -eq $position ]] && (( duration < 300 )); then
    duration=-1
    position=0
  fi
  
  echo "$status|$title|$duration|$position"
}

check_pause_timeout() {
  local status="${1}"
  local current_time
  current_time=$(date +%s)
  
  if [[ "$status" == "playing" ]]; then
    echo "$current_time" > "$PAUSE_STATE_FILE"
    return 1
  fi
  
  if [[ "$status" == "paused" ]]; then
    if [[ -f "$PAUSE_STATE_FILE" ]]; then
      local last_play_time pause_duration
      last_play_time=$(cat "$PAUSE_STATE_FILE")
      pause_duration=$((current_time - last_play_time))
      
      (( pause_duration > PAUSE_TIMEOUT ))
    else
      echo "$current_time" > "$PAUSE_STATE_FILE"
      return 1
    fi
  else
    return 1
  fi
}

format_time() {
  local seconds="${1}"
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    printf "%02d:%02d" $((seconds / 60)) $((seconds % 60))
  else
    date -d@"$seconds" -u +%M:%S 2>/dev/null
  fi
}

should_show_time() {
  local duration="${1}"
  
  (( duration > 10 && duration < 3600 ))
}

export -f get_playerctl_metadata
export -f get_mediacontrol_metadata
export -f parse_playerctl
export -f parse_mediacontrol
export -f check_pause_timeout
export -f format_time
export -f should_show_time
