#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/tmux-config.sh"
source "${SCRIPT_DIR}/themes.sh"

if ! is_option_enabled "@tokyo-night-tmux_show_clients"; then
  exit 0
fi

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

MINIMUM=$(tmux show-option -gv @tokyo-night-tmux_clients_minimum 2>/dev/null)
MINIMUM="${MINIMUM:-2}"

get_client_count() {
  tmux list-clients 2>/dev/null | wc -l | tr -d ' '
}

render_clients_widget() {
  local count
  count=$(get_client_count)
  
  if (( count < MINIMUM )); then
    return
  fi
  
  local icon="󰀫"
  local color="${THEME[cyan]}"
  
  # Build output (consistent format: separator + icon + value)
  echo "#[fg=${color},bg=default]░ ${icon}${RESET} ${count} "
}

render_clients_widget

