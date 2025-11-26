#!/usr/bin/env bash

get_tmux_option() {
  local option="${1}"
  local default="${2:-}"
  local value
  value=$(tmux show-option -gv "$option" 2>/dev/null)
  if [[ -z "$value" ]]; then
    echo "$default"
  else
    echo "$value"
  fi
}

set_tmux_option() {
  local option="${1}"
  local value="${2}"
  tmux set-option -g "$option" "$value" 2>/dev/null
}

is_tmux_option_enabled() {
  local option="${1}"
  local value
  value=$(get_tmux_option "$option" "0")
  [[ "$value" == "1" ]]
}

get_session_name() {
  tmux display-message -p '#S' 2>/dev/null || echo ""
}

is_minimal_session() {
  local minimal_session
  minimal_session=$(get_tmux_option "@tokyo-night-tmux_minimal_session" "")
  local current_session
  current_session=$(get_session_name)

  [[ -n "$minimal_session" ]] && [[ "$minimal_session" == "$current_session" ]]
}

export -f get_tmux_option
export -f set_tmux_option
export -f is_tmux_option_enabled
export -f get_session_name
export -f is_minimal_session

