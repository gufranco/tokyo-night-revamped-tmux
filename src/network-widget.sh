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
source "${LIB_DIR}/format.sh"
source "${LIB_DIR}/platform-detector.sh"
source "${LIB_DIR}/error-logger.sh"
source "${LIB_DIR}/tooltip.sh"

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
SHOW_VPN_NAME=$(tmux show-option -gv @tokyo-night-tmux_netspeed_vpn_name 2>/dev/null)
SHOW_WIFI=$(tmux show-option -gv @tokyo-night-tmux_netspeed_wifi 2>/dev/null)

SHOW_PING="${SHOW_PING:-0}"
SHOW_VPN="${SHOW_VPN:-1}"
SHOW_VPN_NAME="${SHOW_VPN_NAME:-0}"
SHOW_WIFI="${SHOW_WIFI:-0}"
SHOW_CONNECTIONS=$(tmux show-option -gv @tokyo-night-tmux_netspeed_connections 2>/dev/null)
SHOW_INTERFACE=$(tmux show-option -gv @tokyo-night-tmux_netspeed_show_interface 2>/dev/null)

SHOW_CONNECTIONS="${SHOW_CONNECTIONS:-0}"
SHOW_INTERFACE="${SHOW_INTERFACE:-0}"
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

rx_bps=$((rx_diff / TIME_DIFF))
tx_bps=$((tx_diff / TIME_DIFF))

rx_speed=$(format_speed "$rx_diff" "$TIME_DIFF")
tx_speed=$(format_speed "$tx_diff" "$TIME_DIFF")

rx_color=$(get_net_speed_color "$rx_bps")
tx_color=$(get_net_speed_color "$tx_bps")

OUTPUT="${COLOR_CYAN}░${COLOR_RESET}"

if [[ $SHOW_VPN -eq 1 ]]; then
  if detect_vpn >/dev/null 2>&1; then
    if [[ $SHOW_VPN_NAME -eq 1 ]]; then
      vpn_name=$(get_vpn_connection_name)
      if [[ -n "$vpn_name" ]]; then
        OUTPUT="${OUTPUT} ${COLOR_CYAN}${ICON_VPN} ${vpn_name}${COLOR_RESET}"
      else
        OUTPUT="${OUTPUT} ${COLOR_CYAN}${ICON_VPN}${COLOR_RESET}"
      fi
    else
      OUTPUT="${OUTPUT} ${COLOR_CYAN}${ICON_VPN}${COLOR_RESET}"
    fi
  fi
fi

if [[ $SHOW_WIFI -eq 1 ]]; then
  wifi_signal=$(get_wifi_signal_strength)
  if [[ -n "$wifi_signal" ]] && [[ "$wifi_signal" =~ ^-?[0-9]+$ ]] && [[ $wifi_signal -lt 0 ]]; then
    local wifi_color
    if (( wifi_signal >= -50 )); then
      wifi_color="${COLOR_GREEN}"
    elif (( wifi_signal >= -70 )); then
      wifi_color="${COLOR_YELLOW}"
    else
      wifi_color="${COLOR_RED}"
    fi
    OUTPUT="${OUTPUT} ${wifi_color}${ICON_WIFI} ${wifi_signal}dBm${COLOR_RESET}"
  fi
fi

OUTPUT="${OUTPUT} ${rx_color}↓ $(pad_speed "$rx_speed")${COLOR_RESET}"
OUTPUT="${OUTPUT} ${tx_color}↑ $(pad_speed "$tx_speed")${COLOR_RESET}"

if [[ $SHOW_PING -eq 1 ]]; then
  ping_ms=$(get_ping_latency)
  
  if [[ -n "$ping_ms" ]] && [[ "$ping_ms" =~ ^[0-9]+$ ]]; then
    ping_color=$(get_net_ping_color "$ping_ms")
    OUTPUT="${OUTPUT} ${ping_color}󰓅 $(pad_number "$ping_ms" "ms" 5)${COLOR_RESET}"
  fi
fi

if [[ $SHOW_CONNECTIONS -eq 1 ]]; then
  local connections
  connections=$(get_network_connections)
  if [[ -n "$connections" ]] && [[ "$connections" =~ ^[0-9]+$ ]] && [[ $connections -gt 0 ]]; then
    local conn_color
    if (( connections >= 1000 )); then
      conn_color="${COLOR_RED}"
    elif (( connections >= 500 )); then
      conn_color="${COLOR_YELLOW}"
    else
      conn_color="${COLOR_CYAN}"
    fi
    OUTPUT="${OUTPUT} ${conn_color}${ICON_CONNECTIONS} ${connections}${COLOR_RESET}"
  fi
fi

if [[ $SHOW_INTERFACE -eq 1 ]]; then
  OUTPUT="${OUTPUT} ${COLOR_CYAN}${ICON_IP} ${interface}${COLOR_RESET}"
fi

local tooltip_text
tooltip_text=$(generate_network_tooltip)
set_widget_tooltip "network" "$tooltip_text"

RESULT="${OUTPUT} "
set_cached_value "network" "$RESULT"
echo "$RESULT"
