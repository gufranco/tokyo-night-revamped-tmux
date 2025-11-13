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

INTERFACE=$(tmux show-option -gv @tokyo-night-tmux_netspeed_iface 2>/dev/null)
SHOW_IP=$(tmux show-option -gv @tokyo-night-tmux_netspeed_showip 2>/dev/null)
SHOW_PING=$(tmux show-option -gv @tokyo-night-tmux_netspeed_showping 2>/dev/null)
TIME_DIFF=$(tmux show-option -gv @tokyo-night-tmux_netspeed_refresh 2>/dev/null)
SHOW_VPN=$(tmux show-option -gv @tokyo-night-tmux_netspeed_show_vpn 2>/dev/null)
VPN_VERBOSE=$(tmux show-option -gv @tokyo-night-tmux_netspeed_vpn_verbose 2>/dev/null)

SHOW_IP="${SHOW_IP:-0}"
SHOW_PING="${SHOW_PING:-0}"
TIME_DIFF="${TIME_DIFF:-$DEFAULT_NETSPEED_REFRESH}"
SHOW_VPN="${SHOW_VPN:-1}"
VPN_VERBOSE="${VPN_VERBOSE:-0}"

declare -A NET_ICONS=(
  [wifi_up]="#[fg=${THEME[foreground]}]${ICON_WIFI_UP}"
  [wifi_down]="#[fg=${THEME[red]}]${ICON_WIFI_DOWN}"
  [wired_up]="#[fg=${THEME[foreground]}]${ICON_WIRED_UP}"
  [wired_down]="#[fg=${THEME[red]}]${ICON_WIRED_DOWN}"
  [traffic_tx]="#[fg=${THEME[bblue]}]${ICON_TRAFFIC_TX}"
  [traffic_rx]="#[fg=${THEME[bgreen]}]${ICON_TRAFFIC_RX}"
  [ip]="#[fg=${THEME[foreground]}]${ICON_IP}"
  [vpn]="#[fg=${THEME[green]},bold]${ICON_VPN}"
)

get_interface_type() {
  local interface="${1}"
  
  if [[ ${interface} == "en0" ]] || [[ -d /sys/class/net/${interface}/wireless ]]; then
    echo "wifi"
      else
    echo "wired"
  fi
}

get_interface_status() {
  interface_ipv4 "$1" >/dev/null && echo "up" || echo "down"
}

format_vpn_indicator() {
  [[ $1 -ne 1 ]] && return
  
  local vpn_info
  vpn_info=$(detect_vpn) || return
  
  if [[ "$2" == "1" ]]; then
    echo "${NET_ICONS[vpn]} #[fg=${THEME[foreground]}]${vpn_info} "
        else
    echo "${NET_ICONS[vpn]} #[fg=${THEME[green]},bold]VPN "
  fi
}

format_ping_indicator() {
  [[ $1 -ne 1 ]] && return
  
  local ping_ms
  ping_ms=$(get_ping_latency) || return
  
  [[ ! "$ping_ms" =~ ^[0-9]+$ ]] && return
  
  local ping_color
  
  if (( ping_ms < 50 )); then
    ping_color="${THEME[cyan]}"
  elif (( ping_ms < 100 )); then
    ping_color="${THEME[blue]}"
  elif (( ping_ms < 200 )); then
    ping_color="${THEME[yellow]}"
  else
    ping_color="${THEME[red]}"
  fi
  
  echo "#[fg=${ping_color}]${ICON_PING} ${ping_ms}ms "
}

main() {
  local interface ipv4_addr
  
  interface="${INTERFACE}"
  
  if [[ -z "$interface" ]]; then
    interface=$(find_interface) || exit 0
    tmux set-option -g @tokyo-night-tmux_netspeed_iface "$interface"
fi

  local rx1 tx1 rx2 tx2
  read -r rx1 tx1 < <(get_bytes "$interface") || exit 0
sleep "$TIME_DIFF"
  read -r rx2 tx2 < <(get_bytes "$interface") || exit 0
  
  local rx_diff tx_diff
  rx_diff=$((rx2 - rx1))
  tx_diff=$((tx2 - tx1))
  
  local rx_speed tx_speed
  rx_speed="#[fg=${THEME[foreground]}]$(readable_format "$rx_diff" "$TIME_DIFF")"
  tx_speed="#[fg=${THEME[foreground]}]$(readable_format "$tx_diff" "$TIME_DIFF")"
  
  local iface_type iface_status network_icon
  iface_type=$(get_interface_type "$interface")
  iface_status=$(get_interface_status "$interface")
  network_icon="${NET_ICONS[${iface_type}_${iface_status}]}"
  
  ipv4_addr=$(interface_ipv4 "$interface")
  
  local output="#[fg=${THEME[cyan]},bg=default]░${RESET} "
  
  output="${output}$(format_vpn_indicator "$SHOW_VPN" "$VPN_VERBOSE")"
  output="${output}${NET_ICONS[traffic_rx]} $rx_speed ${NET_ICONS[traffic_tx]} $tx_speed $network_icon #[dim]$interface "

  [[ $SHOW_IP -ne 0 ]] && [[ -n "$ipv4_addr" ]] && output="${output}${NET_ICONS[ip]} #[dim]$ipv4_addr "
  
  output="${output}$(format_ping_indicator "$SHOW_PING")"
  
  echo "$output"
}

main
