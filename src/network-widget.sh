#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${LIB_DIR}/network-utils.sh"
source "${LIB_DIR}/themes.sh"
source "${LIB_DIR}/color-scale.sh"
source "${LIB_DIR}/cache.sh"

is_widget_enabled "@tokyo-night-tmux_show_netspeed" || exit 0

REFRESH_RATE=$(get_refresh_rate)
CACHED=$(get_cached_value "network" "$REFRESH_RATE")

if [[ -n "$CACHED" ]]; then
  echo "$CACHED"
  exit 0
fi

INTERFACE=$(tmux show-option -gv @tokyo-night-tmux_netspeed_iface 2>/dev/null)
SHOW_PING=$(tmux show-option -gv @tokyo-night-tmux_netspeed_ping 2>/dev/null)
SHOW_VPN=$(tmux show-option -gv @tokyo-night-tmux_netspeed_vpn 2>/dev/null)

SHOW_PING="${SHOW_PING:-0}"
SHOW_VPN="${SHOW_VPN:-1}"
TIME_DIFF="$REFRESH_RATE"
  
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

# Calcular bytes por segundo
rx_bps=$((rx_diff / TIME_DIFF))
tx_bps=$((tx_diff / TIME_DIFF))

# Formatar velocidades
rx_speed=$(format_speed "$rx_diff" "$TIME_DIFF")
tx_speed=$(format_speed "$tx_diff" "$TIME_DIFF")

# Obter cores baseadas na velocidade
rx_color=$(get_net_speed_color "$rx_bps")
tx_color=$(get_net_speed_color "$tx_bps")

OUTPUT="${COLOR_CYAN}░${COLOR_RESET}"

if [[ $SHOW_VPN -eq 1 ]]; then
  if detect_vpn >/dev/null 2>&1; then
    OUTPUT="${OUTPUT} ${COLOR_CYAN}󰌘${COLOR_RESET}"
  fi
fi

OUTPUT="${OUTPUT} ${rx_color}↓ ${rx_speed}${COLOR_RESET}"
OUTPUT="${OUTPUT} ${tx_color}↑ ${tx_speed}${COLOR_RESET}"

if [[ $SHOW_PING -eq 1 ]]; then
  ping_ms=$(get_ping_latency)
  
  if [[ -n "$ping_ms" ]] && [[ "$ping_ms" =~ ^[0-9]+$ ]]; then
    ping_color=$(get_net_ping_color "$ping_ms")
    OUTPUT="${OUTPUT} ${ping_color}󰓅 ${ping_ms}ms${COLOR_RESET}"
  fi
fi

RESULT="${OUTPUT} "
set_cached_value "network" "$RESULT"
echo "$RESULT"
