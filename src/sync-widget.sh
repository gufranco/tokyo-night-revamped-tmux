#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/tmux-config.sh"
source "${SCRIPT_DIR}/themes.sh"

if ! is_option_enabled "@tokyo-night-tmux_show_sync"; then
  exit 0
fi

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

SYNC_LABEL=$(tmux show-option -gv @tokyo-night-tmux_sync_label 2>/dev/null)
SYNC_LABEL="${SYNC_LABEL:-SYNC}"

is_panes_synchronized() {
  local sync_status
  sync_status=$(tmux show-window-option -v synchronize-panes 2>/dev/null)
  
  [[ "$sync_status" == "on" ]]
}

render_sync_widget() {
  if ! is_panes_synchronized; then
    return
  fi
  
  local icon="󰓦"
  local color="${THEME[yellow]}"  # Yellow - warning/attention
  
  # Build output (consistent format: separator + icon + value)
  echo "#[fg=${color},bg=default]░ ${icon}${RESET} ${SYNC_LABEL} "
}

render_sync_widget

