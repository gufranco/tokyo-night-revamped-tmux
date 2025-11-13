#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${SCRIPT_DIR}/themes.sh"

is_widget_enabled "@tokyo-night-tmux_show_clients" || exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

MINIMUM=$(tmux show-option -gv @tokyo-night-tmux_clients_minimum 2>/dev/null)
MINIMUM="${MINIMUM:-2}"

get_client_count() {
  tmux list-clients 2>/dev/null | wc -l | tr -d ' '
}

main() {
  local count
  
  count=$(get_client_count)
  
  (( count < MINIMUM )) && exit 0
  
  echo "#[fg=${THEME[cyan]},bg=default]░ ${ICON_CLIENTS}${RESET} ${count} "
}

main
