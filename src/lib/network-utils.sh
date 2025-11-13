#!/usr/bin/env bash

get_bytes() {
  local interface="$1"
  
  if [[ "$(uname)" == "Linux" ]]; then
    awk -v interface="$interface" '$1 == interface ":" {print $2, $10}' /proc/net/dev
  elif [[ "$(uname)" == "Darwin" ]]; then
    netstat -ib | awk -v interface="$interface" '/^'"${interface}"'/ {print $7, $10}' | head -n1
  else
    return 1
  fi
}

format_speed() {
  local bytes=$1
  local secs=${2:-1}
  
  local bps=$(( bytes / secs ))
  
  if (( bps < 1024 )); then
    echo "${bps}B/s"
  elif (( bps < 1048576 )); then
    local kb=$(( (bps + 512) / 1024 ))
    echo "${kb}KB/s"
  else
    local mb=$(( (bps + 524288) / 1048576 ))
    echo "${mb}MB/s"
  fi
}

find_interface() {
  local interface
  
  if [[ $(uname) == "Linux" ]]; then
    interface=$(awk '$2 == 00000000 {print $1}' /proc/net/route)
  elif [[ $(uname) == "Darwin" ]]; then
    interface=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
    [[ ${interface:0:4} == "utun" ]] && interface="en0"
  fi
  
  echo "$interface"
}

interface_ipv4() {
  local interface="$1"
  local ipv4_addr
  
  if [[ $(uname) == "Darwin" ]]; then
    ipv4_addr=$(ipconfig getifaddr "$interface" 2>/dev/null)
  elif [[ $(uname) == "Linux" ]]; then
    if command -v ip >/dev/null 2>&1; then
      ipv4_addr=$(ip addr show dev "$interface" 2>/dev/null | grep "inet\b" | awk '{sub("/.*", "", $2); print $2}')
    elif command -v ifconfig >/dev/null 2>&1; then
      ipv4_addr=$(ifconfig "$interface" 2>/dev/null | grep "inet\b" | awk '{print $2}')
    fi
  fi
  
  echo "$ipv4_addr"
  [[ -n "$ipv4_addr" ]]
}

detect_vpn_macos() {
  command -v netstat >/dev/null 2>&1 || return 1
  
  local vpn_routes
  vpn_routes=$(netstat -rn -f inet 2>/dev/null | grep -E "(utun|tun|tap|ipsec|ppp)[0-9]" | grep -v "link#" | grep -E "^[0-9]")
  
  [[ -z "$vpn_routes" ]] && return 1
  
  local vpn_iface
  vpn_iface=$(echo "$vpn_routes" | head -1 | awk '{print $NF}')
  
  if [[ "$vpn_iface" =~ ^utun[0-2]$ ]]; then
    local real_routes
    real_routes=$(echo "$vpn_routes" | grep "$vpn_iface" | grep -v "169.254" | grep -v "224.0.0" | grep -v "255.255.255")
    [[ -z "$real_routes" ]] && return 1
  fi
  
  echo "$vpn_iface"
}

detect_vpn_linux() {
  command -v ip >/dev/null 2>&1 || return 1
  
  local vpn_interfaces
  vpn_interfaces=$(ip link show up | grep -E "^[0-9]+: (tun|tap|wg|ipsec|ppp|vpn|nordlynx|tailscale)[0-9]*:" | awk -F: '{print $2}' | tr -d ' ')
  
  [[ -z "$vpn_interfaces" ]] && return 1
  
  local iface
  for iface in $vpn_interfaces; do
    local ip_addr
    ip_addr=$(ip addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    
    if [[ -n "$ip_addr" ]]; then
      echo "$iface"
      return 0
    fi
  done
  
  return 1
}

detect_vpn() {
  local vpn_iface
  
  if [[ "$(uname)" == "Darwin" ]]; then
    vpn_iface=$(detect_vpn_macos)
  else
    vpn_iface=$(detect_vpn_linux)
  fi
  
  [[ -n "$vpn_iface" ]] && echo "$vpn_iface" && return 0
  return 1
}

get_ping_latency() {
  local cache_file="/tmp/tmux_tokyo_night_ping_cache"
  local cache_ttl=10
  
  if [[ -f "$cache_file" ]]; then
    local current_time cache_time cache_age
    current_time=$(date +%s)
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
      cache_time=$(stat -f "%m" "$cache_file" 2>/dev/null)
    else
      cache_time=$(stat -c "%Y" "$cache_file" 2>/dev/null)
    fi
    
    if [[ -n "$cache_time" ]] && [[ "$cache_time" =~ ^[0-9]+$ ]]; then
      cache_age=$((current_time - cache_time))
      
      if (( cache_age < cache_ttl )); then
        cat "$cache_file"
        return 0
      fi
    fi
  fi
  
  command -v ping >/dev/null 2>&1 || return 1
  
  local ping_ms
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    ping_ms=$(ping -c 1 -W 1000 8.8.8.8 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}' | cut -d'.' -f1)
  else
    ping_ms=$(ping -c 1 -W 1 8.8.8.8 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}' | cut -d'.' -f1)
  fi
  
  [[ -n "$ping_ms" ]] && echo "$ping_ms" | tee "$cache_file"
}

export -f get_bytes
export -f format_speed
export -f find_interface
export -f interface_ipv4
export -f detect_vpn_macos
export -f detect_vpn_linux
export -f detect_vpn
export -f get_ping_latency
