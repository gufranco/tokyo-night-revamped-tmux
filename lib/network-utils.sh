#!/usr/bin/env bash

function get_bytes() {
  local interface="$1"
  if [[ "$(uname)" == "Linux" ]]; then
    awk -v interface="$interface" '$1 == interface ":" {print $2, $10}' /proc/net/dev
  elif [[ "$(uname)" == "Darwin" ]]; then
    netstat -ib | awk -v interface="$interface" '/^'"${interface}"'/ {print $7, $10}' | head -n1
  else
    exit 1
  fi
}

function readable_format() {
  local bytes=$1
  local secs=${2:-1}

  if [[ $bytes -lt 1048576 ]]; then
    echo "$(bc -l <<<"scale=1; $bytes / 1024 / $secs")KB/s"
  else
    echo "$(bc -l <<<"scale=1; $bytes / 1048576 / $secs")MB/s"
  fi
}

function find_interface() {
  local interface
  if [[ $(uname) == "Linux" ]]; then
    interface=$(awk '$2 == 00000000 {print $1}' /proc/net/route)
  elif [[ $(uname) == "Darwin" ]]; then
    interface=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
    [[ ${interface:0:4} == "utun" ]] && interface="en0"
  fi
  echo "$interface"
}

function interface_ipv4() {
  local interface="$1"
  local ipv4_addr
  local status="up"
  if [[ $(uname) == "Darwin" ]]; then
    ipv4_addr=$(ipconfig getifaddr "$interface")
    [[ -z $ipv4_addr ]] && status="down"
  elif [[ $(uname) == "Linux" ]]; then
    if command -v ip >/dev/null 2>&1; then
      ipv4_addr=$(ip addr show dev "$interface" 2>/dev/null | grep "inet\b" | awk '{sub("/.*", "", $2); print $2}')
      [[ -z $ipv4_addr ]] && status="down"
    elif command -v ifconfig >/dev/null 2>&1; then
      ipv4_addr=$(ifconfig "$interface" 2>/dev/null | grep "inet\b" | awk '{print $2}')
      [[ -z $ipv4_addr ]] && status="down"
    elif [[ $(cat "/sys/class/net/$interface/operstate" 2>/dev/null) != "up" ]]; then
      status="down"
    fi
  fi
  echo "$ipv4_addr"
  [[ $status == "up" ]] && return 0 || return 1
}

