#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/widget/widget-loader.sh"
source "${LIB_DIR}/tmux/tmux-ops.sh"
source "${LIB_DIR}/widget/widget-common.sh"
source "${LIB_DIR}/widget/widget-config.sh"

load_widget_dependencies "network"

validate_widget_enabled "@yoru_revamped_show_netspeed"

cached_output=$(get_cached_widget_output "network")
should_use_cache "$cached_output" && echo "$cached_output" && exit 0

INTERFACE=$(get_tmux_option "@yoru_revamped_netspeed_iface" "")
SHOW_PING=$(is_widget_feature_enabled "@yoru_revamped_netspeed_ping" "0")
SHOW_VPN=$(is_widget_feature_enabled "@yoru_revamped_netspeed_vpn" "1")
SHOW_VPN_NAME=$(is_widget_feature_enabled "@yoru_revamped_netspeed_vpn_name" "0")
SHOW_WIFI=$(is_widget_feature_enabled "@yoru_revamped_netspeed_wifi" "0")
SHOW_CONNECTIONS=$(is_widget_feature_enabled "@yoru_revamped_netspeed_connections" "0")
SHOW_INTERFACE=$(is_widget_feature_enabled "@yoru_revamped_netspeed_show_interface" "0")

main() {
  local interface
  interface="${INTERFACE}"

  if [[ -z "$interface" ]]; then
    interface=$(find_interface) || exit 0
    tmux set-option -g @yoru_revamped_netspeed_iface "$interface"
  fi

  source "${LIB_DIR}/network/network-speed.sh"
  local speed_data
  speed_data=$(get_network_speed "$interface")
  read -r rx_diff tx_diff time_diff <<< "$speed_data"

  if [[ -z "$time_diff" ]] || [[ $time_diff -eq 0 ]]; then
    time_diff=1
  fi

  local rx_bps tx_bps rx_speed tx_speed rx_color tx_color
  rx_bps=$((rx_diff / time_diff))
  tx_bps=$((tx_diff / time_diff))

  rx_speed=$(format_speed "$rx_diff" "$time_diff")
  tx_speed=$(format_speed "$tx_diff" "$time_diff")

  rx_color=$(get_net_speed_color "$rx_bps")
  tx_color=$(get_net_speed_color "$tx_bps")

  local OUTPUT
  OUTPUT="${COLOR_CYAN}░${COLOR_RESET}"

  if [[ $SHOW_VPN -eq 1 ]]; then
    if detect_vpn >/dev/null 2>&1; then
      if [[ $SHOW_VPN_NAME -eq 1 ]]; then
        local vpn_name
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
    local wifi_signal wifi_color
    wifi_signal=$(get_wifi_signal_strength)
    if [[ -n "$wifi_signal" ]] && [[ "$wifi_signal" =~ ^-?[0-9]+$ ]] && [[ $wifi_signal -lt 0 ]]; then
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
    local ping_ms ping_color
    ping_ms=$(get_ping_latency)

    if [[ -n "$ping_ms" ]] && [[ "$ping_ms" =~ ^[0-9]+$ ]]; then
      ping_color=$(get_net_ping_color "$ping_ms")
      OUTPUT="${OUTPUT} ${ping_color}󰓅 $(pad_number "$ping_ms" "ms" 5)${COLOR_RESET}"
    fi
  fi

  if [[ $SHOW_CONNECTIONS -eq 1 ]]; then
    local connections conn_color
    connections=$(get_network_connections)
    if [[ -n "$connections" ]] && [[ "$connections" =~ ^[0-9]+$ ]] && [[ $connections -gt 0 ]]; then
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

  local RESULT
  RESULT="${OUTPUT} "
  set_cached_value "network" "$RESULT"
  echo "$RESULT"
}

main
