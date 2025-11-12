#!/usr/bin/env bash
# ==============================================================================
# Tokyo Night Tmux - System Widget
# ==============================================================================
# Unified system monitoring widget (CPU, GPU, Memory, Disk, Battery)
# Simple, clean design with fixed colors and minimal visual noise.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/tmux-config.sh"
source "${SCRIPT_DIR}/themes.sh"

# Check if system widget is enabled
SHOW_SYSTEM=$(tmux show-option -gv @tokyo-night-tmux_show_system 2>/dev/null)
[[ ${SHOW_SYSTEM} -ne 1 ]] && exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# Configuration for individual components
SHOW_CPU=$(tmux show-option -gv @tokyo-night-tmux_system_show_cpu 2>/dev/null)
SHOW_GPU=$(tmux show-option -gv @tokyo-night-tmux_system_show_gpu 2>/dev/null)
SHOW_MEMORY=$(tmux show-option -gv @tokyo-night-tmux_system_show_memory 2>/dev/null)
SHOW_DISK=$(tmux show-option -gv @tokyo-night-tmux_system_show_disk 2>/dev/null)
SHOW_BATTERY=$(tmux show-option -gv @tokyo-night-tmux_system_show_battery 2>/dev/null)
SHOW_MEMORY_PRESSURE=$(tmux show-option -gv @tokyo-night-tmux_system_memory_pressure 2>/dev/null)

# Defaults (all enabled)
SHOW_CPU="${SHOW_CPU:-1}"
SHOW_GPU="${SHOW_GPU:-1}"
SHOW_MEMORY="${SHOW_MEMORY:-1}"
SHOW_DISK="${SHOW_DISK:-1}"
SHOW_BATTERY="${SHOW_BATTERY:-1}"
SHOW_MEMORY_PRESSURE="${SHOW_MEMORY_PRESSURE:-0}"

OUTPUT=""

# ==============================================================================
# CPU Component
# ==============================================================================
if [[ $SHOW_CPU -eq 1 ]]; then
  cpu_usage="0"
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    cpu_line=$(top -l 1 -n 0 | grep "CPU usage")
    cpu_user=$(echo "$cpu_line" | awk '{print $3}' | sed 's/%//')
    cpu_sys=$(echo "$cpu_line" | awk '{print $5}' | sed 's/%//')
    
    if command -v bc >/dev/null 2>&1; then
      cpu_usage=$(echo "$cpu_user + $cpu_sys" | bc | cut -d'.' -f1)
    else
      cpu_usage=$(awk "BEGIN {printf \"%.0f\", $cpu_user + $cpu_sys}")
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    read -r _ user nice system idle _ < /proc/stat
    total_initial=$((user + nice + system + idle))
    idle_initial=$idle
    
    sleep 0.1
    
    read -r _ user nice system idle _ < /proc/stat
    total_final=$((user + nice + system + idle))
    idle_final=$idle
    
    total_diff=$((total_final - total_initial))
    idle_diff=$((idle_final - idle_initial))
    
    if [[ $total_diff -gt 0 ]]; then
      cpu_usage=$(( (total_diff - idle_diff) * 100 / total_diff ))
    fi
  fi
  
  [[ -z "$cpu_usage" ]] && cpu_usage="0"
  [[ "$cpu_usage" -lt 0 ]] && cpu_usage="0"
  [[ "$cpu_usage" -gt 100 ]] && cpu_usage="100"
  
  # Fixed color for CPU (cyan)
  OUTPUT="${OUTPUT}#[fg=${THEME[cyan]},bg=default]󰾆${RESET} ${cpu_usage}%"
fi

# ==============================================================================
# GPU Component
# ==============================================================================
if [[ $SHOW_GPU -eq 1 ]]; then
  gpu_usage="0"
  
  if [[ "$(uname)" == "Darwin" ]] && [[ "$(uname -m)" == "arm64" ]]; then
    windowserver_cpu=$(ps aux | grep "WindowServer" | grep -v grep | awk '{print $3}' | sort -rn | head -1)
    if [[ -n "$windowserver_cpu" ]]; then
      cpu_integer=$(echo "$windowserver_cpu" | tr ',' '.' | cut -d'.' -f1)
      if [[ "$cpu_integer" =~ ^[0-9]+$ ]]; then
        gpu_usage=$(( cpu_integer / 2 ))
        [[ $gpu_usage -gt 100 ]] && gpu_usage=100
      fi
    fi
  elif command -v nvidia-smi >/dev/null 2>&1; then
    gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
  elif command -v rocm-smi >/dev/null 2>&1; then
    gpu_usage=$(rocm-smi --showuse --csv 2>/dev/null | grep -oP '\d+(?=%)')
  fi
  
  gpu_usage="${gpu_usage:-0}"
  
  if [[ "$gpu_usage" =~ ^[0-9]+$ ]] && [[ $gpu_usage -gt 0 ]]; then
    # Fixed color for GPU (blue)
    [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
    OUTPUT="${OUTPUT}#[fg=${THEME[blue]},bg=default]󰾲${RESET} ${gpu_usage}%"
  fi
fi

# ==============================================================================
# Memory Component
# ==============================================================================
if [[ $SHOW_MEMORY -eq 1 ]]; then
  memory_percent=0
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    total_mem=$(sysctl -n hw.memsize)
    page_size=$(pagesize 2>/dev/null || sysctl -n hw.pagesize)
    
    vm_stats=$(vm_stat)
    pages_wired=$(echo "$vm_stats" | awk '/Pages wired down/ {print $NF}' | tr -d '.')
    pages_compressed=$(echo "$vm_stats" | awk '/Pages occupied by compressor/ {print $NF}' | tr -d '.')
    
    used_pages=$((pages_wired + pages_compressed))
    used_mem=$((used_pages * page_size))
    
    memory_percent=$(( (used_mem * 100) / total_mem ))
  elif command -v free >/dev/null 2>&1; then
    total_mem=$(awk '/MemTotal/ {print $2 * 1024}' /proc/meminfo)
    available_mem=$(awk '/MemAvailable/ {print $2 * 1024}' /proc/meminfo)
    used_mem=$(( total_mem - available_mem ))
    memory_percent=$(( (used_mem * 100) / total_mem ))
  fi
  
  [[ -z "$memory_percent" ]] && memory_percent="0"
  [[ "$memory_percent" -lt 0 ]] && memory_percent="0"
  [[ "$memory_percent" -gt 100 ]] && memory_percent="100"
  
  # Fixed color for memory (cyan)
  [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
  OUTPUT="${OUTPUT}#[fg=${THEME[cyan]},bg=default]󰍛${RESET} ${memory_percent}%"
  
  # Memory pressure indicator (ONLY this changes color)
  if [[ $SHOW_MEMORY_PRESSURE -eq 1 ]]; then
    pressure_color=""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
      swapouts=$(echo "$vm_stats" | grep "Swapouts:" | awk '{print $NF}' | tr -d '.')
      
      if (( swapouts > 5000000 )); then
        pressure_color="${THEME[red]}"
      elif (( swapouts > 1000000 )); then
        pressure_color="${THEME[yellow]}"
      else
        pressure_color="${THEME[green]}"
      fi
    else
      if [[ -f /proc/pressure/memory ]]; then
        pressure_some=$(grep "some" /proc/pressure/memory | awk '{print $2}' | cut -d'=' -f2 | cut -d'.' -f1)
        
        if (( pressure_some > 50 )); then
          pressure_color="${THEME[red]}"
        elif (( pressure_some > 10 )); then
          pressure_color="${THEME[yellow]}"
        else
          pressure_color="${THEME[green]}"
        fi
      fi
    fi
    
    [[ -n "$pressure_color" ]] && OUTPUT="${OUTPUT} #[fg=${pressure_color}]●${RESET}"
  fi
fi

# ==============================================================================
# Disk Component
# ==============================================================================
if [[ $SHOW_DISK -eq 1 ]]; then
  DISK_PATH=$(get_tmux_option "@tokyo-night-tmux_system_disk_path" "/")
  disk_info=$(df -h "$DISK_PATH" 2>/dev/null | awk 'NR==2 {print $5}')
  
  if [[ -n "$disk_info" ]]; then
    usage_percent=$(echo "$disk_info" | tr -d '%')
    
    if [[ "$usage_percent" =~ ^[0-9]+$ ]]; then
      [[ "$usage_percent" -lt 0 ]] && usage_percent="0"
      [[ "$usage_percent" -gt 100 ]] && usage_percent="100"
      
      # Fixed color for disk (cyan)
      [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
      OUTPUT="${OUTPUT}#[fg=${THEME[cyan]},bg=default]󰋊${RESET} ${usage_percent}%"
    fi
  fi
fi

# ==============================================================================
# Battery Component
# ==============================================================================
if [[ $SHOW_BATTERY -eq 1 ]]; then
  BATTERY_NAME=$(get_tmux_option "@tokyo-night-tmux_system_battery_name" "")
  BATTERY_LOW=$(get_tmux_option "@tokyo-night-tmux_system_battery_low_threshold" "21")
  
  if [[ "$(uname)" == "Darwin" ]]; then
    default_battery_name="InternalBattery-0"
  else
    default_battery_name="BAT1"
  fi
  
  BATTERY_NAME="${BATTERY_NAME:-$default_battery_name}"
  
  # Check if battery exists
  battery_exists=0
  if [[ "$(uname)" == "Darwin" ]]; then
    pmset -g batt | grep -q "$BATTERY_NAME" && battery_exists=1
  else
    [[ -d "/sys/class/power_supply/$BATTERY_NAME" ]] && battery_exists=1
  fi
  
  if [[ $battery_exists -eq 1 ]]; then
    battery_status=""
    battery_percentage=""
    
    if [[ "$(uname)" == "Darwin" ]]; then
      ac_power=$(pmset -g batt | head -1 | grep -i "AC Power")
      pmstat=$(pmset -g batt | grep "$BATTERY_NAME")
      battery_status=$(echo "$pmstat" | awk '{print $4}' | sed 's/[^a-zA-Z]*//g')
      battery_percentage=$(echo "$pmstat" | awk '{print $3}' | sed 's/[^0-9]*//g')
      
      [[ -n "$ac_power" ]] && battery_status="charging"
    else
      if [[ -f "/sys/class/power_supply/${BATTERY_NAME}/status" && -f "/sys/class/power_supply/${BATTERY_NAME}/capacity" ]]; then
        battery_status=$(<"/sys/class/power_supply/${BATTERY_NAME}/status")
        battery_percentage=$(<"/sys/class/power_supply/${BATTERY_NAME}/capacity")
        
        for adapter in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          if [[ -f "$adapter" ]]; then
            [[ $(<"$adapter") -eq 1 ]] && battery_status="charging" && break
          fi
        done
      fi
    fi
    
    if [[ "$battery_percentage" =~ ^[0-9]+$ ]]; then
      battery_status_lower=$(echo "$battery_status" | tr '[:upper:]' '[:lower:]')
      
      # Determine icon (AC plug or battery level)
      case "${battery_status_lower}" in
      charging|charged|full|ac)
        icon="󰚥"  # Plug icon
        ;;
      discharging)
        icon_idx=$(( battery_percentage / 10 ))
        [[ $icon_idx -gt 10 ]] && icon_idx=10
        icons=("󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
        icon="${icons[$icon_idx]}"
        ;;
      *)
        icon="󱉝"
        ;;
      esac
      
      # Fixed color for battery (yellow), unless critical
      if [[ $battery_percentage -lt $BATTERY_LOW ]]; then
        color="#[fg=${THEME[red]},bg=default]"  # Red only when critical
      else
        color="#[fg=${THEME[yellow]},bg=default]"  # Yellow always
      fi
      
      [[ -n "$OUTPUT" ]] && OUTPUT="${OUTPUT} "
      OUTPUT="${OUTPUT}${color}${icon}${RESET} ${battery_percentage}%"
    fi
  fi
fi

# Output with separator at the beginning
[[ -n "$OUTPUT" ]] && echo "░ ${OUTPUT} "
