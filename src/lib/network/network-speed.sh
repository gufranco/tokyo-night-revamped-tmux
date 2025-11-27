#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."

source "${LIB_DIR}/network/network-utils.sh"

NETWORK_STATE_DIR="/tmp/tmux_tokyo_night_network"
mkdir -p "$NETWORK_STATE_DIR" 2>/dev/null

get_network_speed() {
  local interface="${1}"
  local state_file="${NETWORK_STATE_DIR}/${interface}.state"
  local current_time
  current_time=$(date +%s)

  if [[ ! -f "$state_file" ]]; then
    read -r rx tx < <(get_bytes "$interface" 2>/dev/null || echo "0 0")
    echo "${current_time}:${rx}:${tx}" > "$state_file"
    echo "0 0"
    return
  fi

  local last_data
  last_data=$(cat "$state_file" 2>/dev/null)
  IFS=':' read -r last_time last_rx last_tx <<< "$last_data"

  read -r current_rx current_tx < <(get_bytes "$interface" 2>/dev/null || echo "0 0")
  echo "${current_time}:${current_rx}:${current_tx}" > "$state_file"

  if [[ -z "$last_time" ]] || [[ ! "$last_time" =~ ^[0-9]+$ ]]; then
    echo "0 0"
    return
  fi

  local time_diff
  time_diff=$((current_time - last_time))
  [[ $time_diff -le 0 ]] && time_diff=1

  local rx_diff tx_diff
  rx_diff=$((current_rx - last_rx))
  tx_diff=$((current_tx - last_tx))

  [[ $rx_diff -lt 0 ]] && rx_diff=0
  [[ $tx_diff -lt 0 ]] && tx_diff=0

  echo "${rx_diff} ${tx_diff} ${time_diff}"
}

export -f get_network_speed

