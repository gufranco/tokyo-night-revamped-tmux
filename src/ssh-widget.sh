#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/tmux-config.sh"
source "${SCRIPT_DIR}/themes.sh"

if ! is_option_enabled "@tokyo-night-tmux_show_ssh"; then
  exit 0
fi

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

ONLY_WHEN_CONNECTED=$(tmux show-option -gv @tokyo-night-tmux_ssh_only_when_connected 2>/dev/null)
ONLY_WHEN_CONNECTED="${ONLY_WHEN_CONNECTED:-1}"

SHOW_PORT=$(tmux show-option -gv @tokyo-night-tmux_ssh_show_port 2>/dev/null)
SHOW_PORT="${SHOW_PORT:-0}"

is_ssh_session() {
  [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]
}

get_ssh_info() {
  local username
  local hostname
  local port=""
  
  username="${USER:-$(whoami)}"
  
  if command -v hostname >/dev/null 2>&1; then
    hostname="$(hostname -s 2>/dev/null || hostname)"
  else
    hostname="unknown"
  fi
  
  if [[ "$SHOW_PORT" == "1" ]] && [[ -n "$SSH_CONNECTION" ]]; then
    port=$(echo "$SSH_CONNECTION" | awk '{print $4}')
    if [[ -n "$port" && "$port" != "22" ]]; then
      echo "${username}@${hostname}:${port}"
      return
    fi
  fi
  
  echo "${username}@${hostname}"
}

render_ssh_widget() {
  local is_ssh=0
  
  if is_ssh_session; then
    is_ssh=1
  fi
  
  if [[ "$is_ssh" == "0" ]] && [[ "$ONLY_WHEN_CONNECTED" == "1" ]]; then
    return
  fi
  
  local ssh_info
  ssh_info=$(get_ssh_info)
  
  local icon="󰣀"
  local color
  
  # Color changes when SSH is active
  if [[ "$is_ssh" == "1" ]]; then
    color="${THEME[green]}"  # Green - active SSH
  else
    color="${THEME[cyan]}"  # Cyan - no SSH
  fi
  
  # Build output (consistent format: separator + icon + value)
  echo "#[fg=${color},bg=default]░ ${icon}${RESET} ${ssh_info} "
}

render_ssh_widget

