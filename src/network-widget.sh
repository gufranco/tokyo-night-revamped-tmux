#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${LIB_DIR}/network-utils.sh"
source "${LIB_DIR}/themes.sh"

is_widget_enabled "@tokyo-night-tmux_show_netspeed" || exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"
CYAN="#[fg=${THEME[cyan]},bg=default]"

INTERFACE=$(tmux show-option -gv @tokyo-night-tmux_netspeed_iface 2>/dev/null)
SHOW_PING=$(tmux show-option -gv @tokyo-night-tmux_netspeed_ping 2>/dev/null)
TIME_DIFF=$(tmux show-option -gv @tokyo-night-tmux_netspeed_refresh 2>/dev/null)
SHOW_VPN=$(tmux show-option -gv @tokyo-night-tmux_netspeed_vpn 2>/dev/null)

SHOW_PING="${SHOW_PING:-0}"
TIME_DIFF="${TIME_DIFF:-1}"
SHOW_VPN="${SHOW_VPN:-1}"
  
  interface="${INTERFACE}"
  
  if [[ -z "$interface" ]]; then
    interface=$(find_interface) || exit 0
    tmux set-option -g @tokyo-night-tmux_netspeed_iface "$interface"
fi

  read -r rx1 tx1 < <(get_bytes "$interface") || exit 0
sleep "$TIME_DIFF"
  read -r rx2 tx2 < <(get_bytes "$interface") || exit 0
  
  rx_diff=$((rx2 - rx1))
  tx_diff=$((tx2 - tx1))
  
rx_speed=$(format_speed "$rx_diff" "$TIME_DIFF")
tx_speed=$(format_speed "$tx_diff" "$TIME_DIFF")

OUTPUT="${CYAN}░${RESET}"

if [[ $SHOW_VPN -eq 1 ]]; then
  if detect_vpn >/dev/null 2>&1; then
    OUTPUT="${OUTPUT} ${CYAN}󰌘${RESET}"
  fi
fi

OUTPUT="${OUTPUT} ${CYAN}↓${RESET} ${rx_speed}"
OUTPUT="${OUTPUT} ${CYAN}↑${RESET} ${tx_speed}"

if [[ $SHOW_PING -eq 1 ]]; then
  ping_ms=$(get_ping_latency)
  
  if [[ -n "$ping_ms" ]] && [[ "$ping_ms" =~ ^[0-9]+$ ]]; then
    OUTPUT="${OUTPUT} ${CYAN}󰓅${RESET} ${ping_ms}ms"
  fi
fi

echo "${OUTPUT} "
