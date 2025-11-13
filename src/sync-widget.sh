#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${SCRIPT_DIR}/themes.sh"

is_widget_enabled "@tokyo-night-tmux_show_sync" || exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

SYNC_LABEL=$(tmux show-option -gv @tokyo-night-tmux_sync_label 2>/dev/null)
SYNC_LABEL="${SYNC_LABEL:-SYNC}"

is_panes_synchronized() {
  local sync_status
  sync_status=$(tmux show-window-option -v synchronize-panes 2>/dev/null)
  
  [[ "$sync_status" == "on" ]]
}

main() {
  is_panes_synchronized || exit 0
  
  echo "#[fg=${THEME[cyan]},bg=default]░ ${ICON_SYNC}${RESET} ${SYNC_LABEL} "
}

main
