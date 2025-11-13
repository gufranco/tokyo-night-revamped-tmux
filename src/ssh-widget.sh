#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${SCRIPT_DIR}/themes.sh"

is_widget_enabled "@tokyo-night-tmux_show_ssh" || exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

ONLY_WHEN_CONNECTED=$(tmux show-option -gv @tokyo-night-tmux_ssh_only_when_connected 2>/dev/null)
SHOW_PORT=$(tmux show-option -gv @tokyo-night-tmux_ssh_show_port 2>/dev/null)

ONLY_WHEN_CONNECTED="${ONLY_WHEN_CONNECTED:-1}"
SHOW_PORT="${SHOW_PORT:-0}"

is_ssh_session() {
  [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]
}

get_ssh_info() {
  local username hostname port
  
  username="${USER:-$(whoami)}"
  hostname=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "unknown")
  
  if [[ "$SHOW_PORT" == "1" ]] && [[ -n "$SSH_CONNECTION" ]]; then
    port=$(echo "$SSH_CONNECTION" | awk '{print $4}')
    if [[ -n "$port" ]] && [[ "$port" != "22" ]]; then
      echo "${username}@${hostname}:${port}"
      return
    fi
  fi
  
  echo "${username}@${hostname}"
}

main() {
  local is_ssh=0 ssh_info
  
  is_ssh_session && is_ssh=1
  
  [[ "$is_ssh" == "0" ]] && [[ "$ONLY_WHEN_CONNECTED" == "1" ]] && exit 0
  
  ssh_info=$(get_ssh_info)
  
  echo "#[fg=${THEME[cyan]},bg=default]░ ${ICON_SSH}${RESET} ${ssh_info} "
}

main
