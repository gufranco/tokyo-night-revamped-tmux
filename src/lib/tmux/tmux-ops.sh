#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."

if [[ -f "${LIB_DIR}/utils/tmux-cache.sh" ]]; then
  source "${LIB_DIR}/utils/tmux-cache.sh"
fi

get_tmux_option() {
  local option="${1}"
  local default="${2:-}"

  if declare -f get_cached_tmux_option >/dev/null 2>&1; then
    get_cached_tmux_option "$option" "$default"
  else
    local value
    value=$(tmux show-option -gv "$option" 2>/dev/null)
    [[ -z "$value" ]] && echo "$default" || echo "$value"
  fi
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
  minimal_session=$(get_tmux_option "@yoru_minimal_session" "")
  [[ -n "$minimal_session" ]] && [[ "$minimal_session" == "$(get_session_name)" ]]
}

export -f get_tmux_option
export -f set_tmux_option
export -f is_tmux_option_enabled
export -f get_session_name
export -f is_minimal_session

