#!/usr/bin/env bash
#<------------------------------Netspeed widget for TMUX------------------------------------>
# author : @tribhuwan-kumar
# email : freakybytes@duck.com
#<------------------------------------------------------------------------------------------>

# Check if enabled
ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_netspeed 2>/dev/null)
[[ ${ENABLED} -ne 1 ]] && exit 0

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$ROOT_DIR/src/themes.sh"
source "$ROOT_DIR/lib/network-utils.sh"

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# Configuration
INTERFACE=$(tmux show-option -gv @tokyo-night-tmux_netspeed_iface 2>/dev/null)
SHOW_IP=$(tmux show-option -gv @tokyo-night-tmux_netspeed_showip 2>/dev/null)
SHOW_PING=$(tmux show-option -gv @tokyo-night-tmux_netspeed_showping 2>/dev/null)
TIME_DIFF=$(tmux show-option -gv @tokyo-night-tmux_netspeed_refresh 2>/dev/null)
SHOW_VPN=$(tmux show-option -gv @tokyo-night-tmux_netspeed_show_vpn 2>/dev/null)
VPN_VERBOSE=$(tmux show-option -gv @tokyo-night-tmux_netspeed_vpn_verbose 2>/dev/null)

SHOW_IP=${SHOW_IP:-0}
SHOW_PING=${SHOW_PING:-0}
TIME_DIFF=${TIME_DIFF:-1}
SHOW_VPN=${SHOW_VPN:-1}
VPN_VERBOSE=${VPN_VERBOSE:-0}

# Icons
declare -A NET_ICONS
NET_ICONS[wifi_up]="#[fg=${THEME[foreground]}]\U000f05a9"
NET_ICONS[wifi_down]="#[fg=${THEME[red]}]\U000f05aa"
NET_ICONS[wired_up]="#[fg=${THEME[foreground]}]\U000f0318"
NET_ICONS[wired_down]="#[fg=${THEME[red]}]\U000f0319"
NET_ICONS[traffic_tx]="#[fg=${THEME[bblue]}]\U000f06f6"
NET_ICONS[traffic_rx]="#[fg=${THEME[bgreen]}]\U000f06f4"
NET_ICONS[ip]="#[fg=${THEME[foreground]}]\U000f0a5f"
NET_ICONS[vpn]="#[fg=${THEME[green]},bold]󰌘"

detect_vpn() {
  local os_type
  os_type="$(uname -s)"

  case "$os_type" in
    "Darwin")
      detect_vpn_macos
      ;;
    "Linux")
      detect_vpn_linux
      ;;
    *)
      return 1
      ;;
  esac
}

detect_vpn_macos() {
  if command -v netstat >/dev/null 2>&1; then
    local vpn_routes
    vpn_routes=$(netstat -rn -f inet 2>/dev/null | grep -E "(utun|tun|tap|ipsec|ppp)[0-9]" | grep -v "link#" | grep -E "^[0-9]")

    if [[ -n "$vpn_routes" ]]; then
      local vpn_iface
      vpn_iface=$(echo "$vpn_routes" | head -1 | awk '{print $NF}')

      if [[ "$vpn_iface" =~ ^utun[0-2]$ ]]; then
        local real_routes
        real_routes=$(echo "$vpn_routes" | grep "$vpn_iface" | grep -v "169.254" | grep -v "224.0.0" | grep -v "255.255.255")
        if [[ -z "$real_routes" ]]; then
          return 1
        fi
      fi

      if [[ "$VPN_VERBOSE" == "1" ]]; then
        echo "$vpn_iface"
      else
        echo "vpn"
      fi
      return 0
    fi
  fi

  if command -v ifconfig >/dev/null 2>&1; then
    local vpn_interfaces
    vpn_interfaces=$(ifconfig | grep -E "^(tun|tap)[0-9]+:" | cut -d: -f1)

    for iface in $vpn_interfaces; do
      local ip
      ip=$(ifconfig "$iface" 2>/dev/null | grep "inet " | awk '{print $2}')
      if [[ -n "$ip" ]]; then
        if [[ "$VPN_VERBOSE" == "1" ]]; then
          echo "$iface"
        else
          echo "vpn"
        fi
        return 0
      fi
    done
  fi

  return 1
}

detect_vpn_linux() {
  if command -v ip >/dev/null 2>&1; then
    local vpn_interfaces
    vpn_interfaces=$(ip link show up | grep -E "^[0-9]+: (tun|tap|wg|ipsec|ppp|vpn|nordlynx|tailscale)[0-9]*:" | awk -F: '{print $2}' | tr -d ' ')

    if [[ -n "$vpn_interfaces" ]]; then
      for iface in $vpn_interfaces; do
        local ip
        ip=$(ip addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        if [[ -n "$ip" ]]; then
          if [[ "$VPN_VERBOSE" == "1" ]]; then
            echo "$iface"
          else
            echo "vpn"
          fi
          return 0
        fi
      done
    fi

    local vpn_routes
    vpn_routes=$(ip route | grep -E "(tun|tap|wg|ipsec|ppp|vpn|nordlynx|tailscale)[0-9]")
    if [[ -n "$vpn_routes" ]]; then
      local vpn_iface
      vpn_iface=$(echo "$vpn_routes" | head -1 | awk '{print $3}')

      if [[ "$VPN_VERBOSE" == "1" ]]; then
        echo "$vpn_iface"
      else
        echo "vpn"
      fi
      return 0
    fi
  fi

  return 1
}

# Determine interface if not set
if [[ -z $INTERFACE ]]; then
  INTERFACE=$(find_interface)
  [[ -z $INTERFACE ]] && exit 1
  tmux set-option -g @tokyo-night-tmux_netspeed_iface "$INTERFACE"
fi

read -r RX1 TX1 < <(get_bytes "$INTERFACE")
sleep "$TIME_DIFF"
read -r RX2 TX2 < <(get_bytes "$INTERFACE")

RX_DIFF=$((RX2 - RX1))
TX_DIFF=$((TX2 - TX1))

RX_SPEED="#[fg=${THEME[foreground]}]$(readable_format "$RX_DIFF" "$TIME_DIFF")"
TX_SPEED="#[fg=${THEME[foreground]}]$(readable_format "$TX_DIFF" "$TIME_DIFF")"

if [[ ${INTERFACE} == "en0" ]] || [[ -d /sys/class/net/${INTERFACE}/wireless ]]; then
  IFACE_TYPE="wifi"
else
  IFACE_TYPE="wired"
fi

if IPV4_ADDR=$(interface_ipv4 "$INTERFACE"); then
  IFACE_STATUS="up"
else
  IFACE_STATUS="down"
fi

NETWORK_ICON=${NET_ICONS[${IFACE_TYPE}_${IFACE_STATUS}]}

OUTPUT="${RESET}░ "

# VPN indicator
if [[ ${SHOW_VPN} -eq 1 ]]; then
  vpn_info=$(detect_vpn)
  if [[ -n "$vpn_info" ]]; then
    OUTPUT+="${NET_ICONS[vpn]}"
    if [[ "$VPN_VERBOSE" == "1" ]]; then
      OUTPUT+=" #[fg=${THEME[foreground]}]${vpn_info} "
    else
      OUTPUT+=" #[fg=${THEME[green]},bold]VPN "
    fi
  fi
fi

OUTPUT+="${NET_ICONS[traffic_rx]} $RX_SPEED ${NET_ICONS[traffic_tx]} $TX_SPEED $NETWORK_ICON #[dim]$INTERFACE "

# Show IP
if [[ ${SHOW_IP} -ne 0 ]] && [[ -n $IPV4_ADDR ]]; then
  OUTPUT+="${NET_ICONS[ip]} #[dim]$IPV4_ADDR "
fi

# Show ping
if [[ ${SHOW_PING} -ne 0 ]]; then
  cache_file="/tmp/tmux_tokyo_night_ping_cache"
  cache_ttl=10

  use_cache=0
  if [[ -f "$cache_file" ]]; then
    current_time=$(date +%s)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      cache_time=$(stat -f "%m" "$cache_file" 2>/dev/null)
    else
      cache_time=$(stat -c "%Y" "$cache_file" 2>/dev/null)
    fi

    if [[ -n "$cache_time" ]] && [[ "$cache_time" =~ ^[0-9]+$ ]]; then
      cache_age=$((current_time - cache_time))
      if [[ $cache_age -lt $cache_ttl ]]; then
        use_cache=1
      fi
    fi
  fi

  if [[ $use_cache -eq 1 ]]; then
    ping_ms=$(cat "$cache_file")
  else
    if command -v ping >/dev/null 2>&1; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        ping_ms=$(ping -c 1 -W 1000 8.8.8.8 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}' | cut -d'.' -f1)
      else
        ping_ms=$(ping -c 1 -W 1 8.8.8.8 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}' | cut -d'.' -f1)
      fi
      [[ -n "$ping_ms" ]] && echo "$ping_ms" > "$cache_file"
    fi
  fi

  if [[ -n "$ping_ms" ]] && [[ "$ping_ms" =~ ^[0-9]+$ ]]; then
    if [[ $ping_ms -lt 50 ]]; then
      ping_color="#[fg=#73daca]"
    elif [[ $ping_ms -lt 100 ]]; then
      ping_color="#[fg=#7aa2f7]"
    elif [[ $ping_ms -lt 200 ]]; then
      ping_color="#[fg=#e0af68]"
    else
      ping_color="#[fg=#f7768e]"
    fi
    OUTPUT+="${ping_color}󰖩 ${ping_ms}ms "
  fi
fi

echo -e "$OUTPUT"
