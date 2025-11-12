#!/usr/bin/env bash
# ==============================================================================
# Tokyo Night Tmux - GPU Widget
# ==============================================================================
# Displays GPU usage for Apple Silicon, NVIDIA, and AMD GPUs.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/tmux-config.sh"
source "${LIB_DIR}/system.sh"
source "${SCRIPT_DIR}/themes.sh"

if ! is_option_enabled "@tokyo-night-tmux_show_gpu"; then
  exit 0
fi

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# ==============================================================================
# GPU Detection Functions
# ==============================================================================

get_nvidia_gpu_usage() {
  if ! command_exists nvidia-smi; then
    return 1
  fi
  
  local gpu_usage
  gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
  
  echo "nvidia ${gpu_usage:-0}"
  return 0
}

get_amd_gpu_usage() {
  if ! command_exists rocm-smi; then
    return 1
  fi
  
  local gpu_usage
  gpu_usage=$(rocm-smi --showuse --csv 2>/dev/null | grep -oP '\d+(?=%)')
  
  echo "amd ${gpu_usage:-0}"
  return 0
}

get_apple_gpu_usage() {
  if [[ "$(uname)" != "Darwin" ]] || [[ "$(uname -m)" != "arm64" ]]; then
    return 1
  fi
  
  # Estimate GPU usage from WindowServer CPU (graphics manager)
  local windowserver_cpu
  windowserver_cpu=$(ps aux | grep "WindowServer" | grep -v grep | awk '{print $3}' | sort -rn | head -1)
  
  if [[ -z "$windowserver_cpu" ]]; then
    echo "apple 0"
    return 0
  fi
  
  local cpu_integer
  cpu_integer=$(echo "$windowserver_cpu" | tr ',' '.' | cut -d'.' -f1)
  
  if [[ ! "$cpu_integer" =~ ^[0-9]+$ ]]; then
    echo "apple 0"
    return 0
  fi
  
  local gpu_usage
  gpu_usage=$(( cpu_integer / 2 ))
  
  if (( gpu_usage > 100 )); then
    gpu_usage=100
  fi
  
  echo "apple ${gpu_usage}"
  return 0
}

get_intel_gpu_usage() {
  if [[ "$(uname)" == "Darwin" ]] && command_exists ioreg; then
    local intel_gpu
    intel_gpu=$(ioreg -l | grep "IntelAccelerator")
    
    if [[ -n "$intel_gpu" ]]; then
      echo "intel 0"
      return 0
    fi
  fi
  
  return 1
}

get_gpu_stats() {
  local stats
  
  if stats=$(get_apple_gpu_usage 2>/dev/null); then
    echo "$stats"
    return 0
  fi
  
  if stats=$(get_nvidia_gpu_usage 2>/dev/null); then
    echo "$stats"
    return 0
  fi
  
  if stats=$(get_amd_gpu_usage 2>/dev/null); then
    echo "$stats"
    return 0
  fi
  
  if stats=$(get_intel_gpu_usage 2>/dev/null); then
    echo "$stats"
    return 0
  fi
  
  return 1
}

# ==============================================================================
# Render Function
# ==============================================================================

render_gpu_widget() {
  local stats
  stats=$(get_gpu_stats)
  
  if [[ -z "$stats" ]]; then
    return
  fi
  
  local gpu_type usage
  gpu_type=$(echo "$stats" | awk '{print $1}')
  usage=$(echo "$stats" | awk '{print $2}')
  
  if [[ ! "$usage" =~ ^[0-9]+$ ]]; then
    usage=0
  fi
  
  local icon="󰾲"
  local color
  
  # Color coding (matches iStats thresholds)
  if (( usage >= 80 )); then
    color="#[fg=${THEME[red]},bg=default,bold]"  # Red
  elif (( usage >= 50 )]; then
    color="#[fg=${THEME[yellow]},bg=default]"  # Yellow
  else
    color="#[fg=${THEME[blue]},bg=default]"  # Blue
  fi
  
  # Build output (consistent format: separator + icon + value)
  echo "${color}░ ${icon}${RESET} ${usage}% "
}

# ==============================================================================
# Main
# ==============================================================================

render_gpu_widget

