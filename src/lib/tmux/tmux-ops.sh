#!/usr/bin/env bash

get_tmux_option() {
  local option="${1}"
  local default="${2:-}"
  local value
  value=$(tmux show-option -gv "$option" 2>/dev/null)
  [[ -z "$value" ]] && echo "$default" || echo "$value"
}

set_tmux_option() {
  tmux set-option -g "${1}" "${2}" 2>/dev/null
}

is_tmux_option_enabled() {
  [[ "$(get_tmux_option "${1}" "0")" == "1" ]]
}

get_session_name() {
  tmux display-message -p '#S' 2>/dev/null || echo ""
}

is_minimal_session() {
  local minimal_session
  minimal_session=$(get_tmux_option "@tokyo-night-tmux_minimal_session" "")
  [[ -n "$minimal_session" ]] && [[ "$minimal_session" == "$(get_session_name)" ]]
}

export -f get_tmux_option
export -f set_tmux_option
export -f is_tmux_option_enabled
export -f get_session_name
export -f is_minimal_session

