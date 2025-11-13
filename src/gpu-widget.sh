#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${SCRIPT_DIR}/themes.sh"

is_widget_enabled "@tokyo-night-tmux_show_gpu" || exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

get_gpu_usage_apple_silicon() {
  local windowserver_cpu cpu_integer
  
  windowserver_cpu=$(ps aux 2>/dev/null | grep "WindowServer" | grep -v grep | awk '{print $3}' | sort -rn | head -1)
  
  [[ -z "$windowserver_cpu" ]] && return 1
  
  cpu_integer=$(echo "$windowserver_cpu" | tr ',' '.' | cut -d'.' -f1)
  
  [[ ! "$cpu_integer" =~ ^[0-9]+$ ]] && return 1
  
  local gpu_usage=$(( cpu_integer / 2 ))
  
  (( gpu_usage > 100 )) && gpu_usage=100
  
  echo "$gpu_usage"
}

get_gpu_usage_nvidia() {
  command -v nvidia-smi >/dev/null 2>&1 || return 1
  
  nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1
}

get_gpu_usage_amd() {
  command -v rocm-smi >/dev/null 2>&1 || return 1
  
  rocm-smi --showuse --csv 2>/dev/null | grep -oP '\d+(?=%)'
}

get_gpu_usage() {
  local usage
  
  if is_apple_silicon; then
    usage=$(get_gpu_usage_apple_silicon)
  elif usage=$(get_gpu_usage_nvidia); then
    :
  elif usage=$(get_gpu_usage_amd); then
    :
  else
    return 1
  fi
  
  validate_number "${usage}" "0"
}

main() {
  local gpu_usage color output
  
  gpu_usage=$(get_gpu_usage) || exit 0
  
  (( gpu_usage == 0 )) && exit 0
  
  output=$(format_widget_output "${THEME[cyan]}" "${ICON_GPU}" "$gpu_usage" "%" "$RESET")
  
  echo "$output"
}

main
