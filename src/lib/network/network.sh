#!/usr/bin/env bash

if [[ -z "${LIB_DIR:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  UTILS_DIR="${SCRIPT_DIR}/../utils"
else
  UTILS_DIR="${LIB_DIR}/utils"
fi

source "${UTILS_DIR}/has-command.sh"

get_default_network_interface() {
  local os
  os="$(get_os)"

  case "${os}" in
    Darwin*)
      route -n get default 2>/dev/null | awk '/interface:/ {print $2}' || echo "en0"
      ;;
    Linux*)
      if [[ -f /proc/net/route ]]; then
        awk '$2 == "00000000" {print $1; exit}' /proc/net/route 2>/dev/null || echo "eth0"
      else
        echo "eth0"
      fi
      ;;
    *)
      echo "eth0"
      ;;
  esac
}

get_network_connections() {
  local os
  os="$(get_os)"
  local connections=0

  case "${os}" in
    Darwin*)
      if has_command netstat; then
        connections=$(netstat -an 2>/dev/null | grep -cE "^tcp[46]|^udp[46]" || echo "0")
      fi
      ;;
    Linux*)
      if [[ -f /proc/net/sockstat ]]; then
        connections=$(awk '/TCP:/ {print $3}' /proc/net/sockstat 2>/dev/null || echo "0")
      elif has_command ss; then
        connections=$(ss -tun 2>/dev/null | grep -cE "^ESTAB|^LISTEN" || echo "0")
      elif has_command netstat; then
        connections=$(netstat -tun 2>/dev/null | grep -cE "^tcp|^udp" || echo "0")
      fi
      ;;
  esac

  echo "${connections:-0}"
}

get_vpn_connection_name() {
  local os
  os="$(get_os)"
  local vpn_name=""

  case "${os}" in
    Darwin*)
      if has_command scutil; then
        vpn_name=$(scutil --nc list 2>/dev/null | awk '/Connected/ {print $NF; exit}')
      fi
      ;;
    Linux*)
      if has_command nmcli; then
        vpn_name=$(nmcli connection show --active 2>/dev/null | awk '/vpn|VPN/ {print $1; exit}')
      elif [[ -d /sys/class/net ]]; then
        for iface in /sys/class/net/tun* /sys/class/net/wg* /sys/class/net/ppp*; do
          if [[ -d "$iface" ]]; then
            vpn_name=$(basename "$iface")
            break
          fi
        done
      fi
      ;;
  esac

  echo "$vpn_name"
}

get_wifi_signal_strength() {
  local os
  os="$(get_os)"
  local signal=0

  case "${os}" in
    Darwin*)
      if has_command /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport; then
        signal=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk '/agrCtlRSSI/ {print $2}')
      elif has_command networksetup; then
        local wifi_interface
        wifi_interface=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|AirPort/ {getline; print $2}')
        if [[ -n "$wifi_interface" ]]; then
          signal=$(networksetup -getairportnetwork "$wifi_interface" 2>/dev/null | awk '{print $NF}')
        fi
      fi
      ;;
    Linux*)
      local wifi_interface
      wifi_interface=$(iwconfig 2>/dev/null | awk '/IEEE 802.11/ {print $1; exit}')
      if [[ -n "$wifi_interface" ]]; then
        signal=$(iwconfig "$wifi_interface" 2>/dev/null | awk -F'=' '/Signal level/ {gsub(/[^0-9-]/, "", $2); print $2}')
      elif [[ -f /proc/net/wireless ]]; then
        signal=$(awk 'NR>2 {print $4; exit}' /proc/net/wireless 2>/dev/null)
      fi
      ;;
  esac

  [[ -n "$signal" ]] && [[ "$signal" =~ ^-?[0-9]+$ ]] && echo "$signal" || echo "0"
}

export -f get_default_network_interface
export -f get_network_connections
export -f get_vpn_connection_name
export -f get_wifi_signal_strength

