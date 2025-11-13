#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${LIB_DIR}/platform-detector.sh"
source "${SCRIPT_DIR}/themes.sh"

is_widget_enabled "@tokyo-night-tmux_show_system" || exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"
CYAN="#[fg=${THEME[cyan]},bg=default]"

SHOW_CPU=$(tmux show-option -gv @tokyo-night-tmux_system_cpu 2>/dev/null)
SHOW_GPU=$(tmux show-option -gv @tokyo-night-tmux_system_gpu 2>/dev/null)
SHOW_MEMORY=$(tmux show-option -gv @tokyo-night-tmux_system_memory 2>/dev/null)
SHOW_SWAP=$(tmux show-option -gv @tokyo-night-tmux_system_swap 2>/dev/null)
SHOW_DISK=$(tmux show-option -gv @tokyo-night-tmux_system_disk 2>/dev/null)
SHOW_BATTERY=$(tmux show-option -gv @tokyo-night-tmux_system_battery 2>/dev/null)

SHOW_CPU="${SHOW_CPU:-1}"
SHOW_GPU="${SHOW_GPU:-1}"
SHOW_MEMORY="${SHOW_MEMORY:-1}"
SHOW_SWAP="${SHOW_SWAP:-1}"
SHOW_DISK="${SHOW_DISK:-1}"
SHOW_BATTERY="${SHOW_BATTERY:-1}"

main() {
  local output=""
  
if [[ $SHOW_CPU -eq 1 ]]; then
    local cpu_usage
    cpu_usage=$(get_cpu_usage_percentage)
    cpu_usage=$(validate_percentage "$cpu_usage")
    output="${CYAN}󰾆${RESET} ${cpu_usage}%"
fi

  if [[ $SHOW_GPU -eq 1 ]] && is_apple_silicon; then
    local gpu_usage windowserver_cpu cpu_int
    windowserver_cpu=$(ps aux 2>/dev/null | grep "WindowServer" | grep -v grep | awk '{print $3}' | sort -rn | head -1)
    cpu_int=$(echo "$windowserver_cpu" | tr ',' '.' | cut -d'.' -f1)
    
    if [[ "$cpu_int" =~ ^[0-9]+$ ]]; then
      gpu_usage=$(( cpu_int / 2 ))
      (( gpu_usage > 100 )) && gpu_usage=100
      (( gpu_usage < 1 )) && gpu_usage=1
    else
      gpu_usage=1
    fi
    
    [[ -n "$output" ]] && output="${output} "
    output="${output}${CYAN}󰢮${RESET} ${gpu_usage}%"
  fi
  
if [[ $SHOW_MEMORY -eq 1 ]]; then
    local mem_total mem_used mem_percent
  
    if is_macos; then
      mem_total=$(sysctl -n hw.memsize 2>/dev/null)
      local page_size vm_stats pages_wired pages_compressed
    page_size=$(pagesize 2>/dev/null || sysctl -n hw.pagesize 2>/dev/null)
      vm_stats=$(vm_stat 2>/dev/null)
      pages_wired=$(echo "$vm_stats" | awk '/Pages wired down/ {print $NF}' | tr -d '.')
      pages_compressed=$(echo "$vm_stats" | awk '/Pages occupied by compressor/ {print $NF}' | tr -d '.')
      mem_used=$(( (pages_wired + pages_compressed) * page_size ))
      mem_percent=$(( (mem_used * 100) / mem_total ))
    else
      mem_total=$(awk '/MemTotal/ {print $2 * 1024}' /proc/meminfo 2>/dev/null)
      local mem_available
      mem_available=$(awk '/MemAvailable/ {print $2 * 1024}' /proc/meminfo 2>/dev/null)
      mem_used=$(( mem_total - mem_available ))
      mem_percent=$(( (mem_used * 100) / mem_total ))
    fi
    
    mem_percent=$(validate_percentage "$mem_percent")
  
    [[ -n "$output" ]] && output="${output} "
    output="${output}${CYAN}󰍛${RESET} ${mem_percent}%"
  fi
  
  if [[ $SHOW_SWAP -eq 1 ]]; then
    local swap_total swap_used swap_percent
    
    if is_macos; then
      local sysctl_output
      sysctl_output=$(sysctl -n vm.swapusage 2>/dev/null)
      
      if [[ -n "$sysctl_output" ]]; then
        swap_total=$(echo "$sysctl_output" | grep -oE 'total = [0-9,]+' | grep -oE '[0-9,]+' | tr -d ',')
        swap_used=$(echo "$sysctl_output" | grep -oE 'used = [0-9,]+' | grep -oE '[0-9,]+' | tr -d ',')
        
        if [[ "$swap_total" =~ ^[0-9]+$ ]] && (( swap_total > 0 )); then
          swap_percent=$(( (swap_used * 100) / swap_total ))
          swap_percent=$(validate_percentage "$swap_percent")
          
          [[ -n "$output" ]] && output="${output} "
          output="${output}${CYAN}${ICON_SWAP}${RESET} ${swap_percent}%"
      fi
    fi
    else
      if command -v free >/dev/null 2>&1; then
        swap_total=$(free | awk '/Swap:/ {print $2}')
        swap_used=$(free | awk '/Swap:/ {print $3}')
    
        if [[ "$swap_total" =~ ^[0-9]+$ ]] && (( swap_total > 0 )); then
          swap_percent=$(( (swap_used * 100) / swap_total ))
          swap_percent=$(validate_percentage "$swap_percent")
          
          [[ -n "$output" ]] && output="${output} "
          output="${output}${CYAN}${ICON_SWAP}${RESET} ${swap_percent}%"
      fi
    fi
  fi
fi

if [[ $SHOW_DISK -eq 1 ]]; then
    local disk_path disk_info disk_percent
    disk_path=$(tmux show-option -gv @tokyo-night-tmux_system_disk_path 2>/dev/null)
    disk_path="${disk_path:-/}"
    disk_info=$(df -h "$disk_path" 2>/dev/null | awk 'NR==2 {print $5}')
  
  if [[ -n "$disk_info" ]]; then
      disk_percent=$(echo "$disk_info" | tr -d '%')
      disk_percent=$(validate_percentage "$disk_percent")
      
      [[ -n "$output" ]] && output="${output} "
      output="${output}${CYAN}󰋊${RESET} ${disk_percent}%"
    fi
  fi
  
if [[ $SHOW_BATTERY -eq 1 ]]; then
    local battery_name battery_threshold battery_exists=0
    battery_name=$(tmux show-option -gv @tokyo-night-tmux_system_battery_name 2>/dev/null)
    battery_threshold=$(tmux show-option -gv @tokyo-night-tmux_system_battery_threshold 2>/dev/null)
    battery_threshold="${battery_threshold:-$DEFAULT_BATTERY_LOW}"
  
    if is_macos; then
      battery_name="${battery_name:-InternalBattery-0}"
      pmset -g batt 2>/dev/null | grep -q "$battery_name" && battery_exists=1
  else
      battery_name="${battery_name:-BAT1}"
      [[ -d "/sys/class/power_supply/$battery_name" ]] && battery_exists=1
  fi
  
  if [[ $battery_exists -eq 1 ]]; then
      local battery_status battery_percent icon color
    
      if is_macos; then
        local ac_power pmstat
      ac_power=$(pmset -g batt 2>/dev/null | head -1 | grep -i "AC Power")
        pmstat=$(pmset -g batt 2>/dev/null | grep "$battery_name")
      battery_status=$(echo "$pmstat" | awk '{print $4}' | sed 's/[^a-zA-Z]*//g')
        battery_percent=$(echo "$pmstat" | awk '{print $3}' | sed 's/[^0-9]*//g')
      [[ -n "$ac_power" ]] && battery_status="charging"
    else
        battery_status=$(<"/sys/class/power_supply/${battery_name}/status")
        battery_percent=$(<"/sys/class/power_supply/${battery_name}/capacity")
      fi
      
      battery_percent=$(validate_percentage "$battery_percent")
      
      local status_lower
      status_lower=$(echo "$battery_status" | tr '[:upper:]' '[:lower:]')
      
      case "${status_lower}" in
      charging|charged|full|ac)
          icon="${ICON_BATTERY_PLUG}"
        ;;
      discharging)
          local idx=$(( battery_percent / 10 ))
          (( idx > 10 )) && idx=10
          icon="${BATTERY_ICONS[$idx]}"
        ;;
      *)
          icon="${ICON_BATTERY_NO}"
        ;;
      esac
      
      [[ -n "$output" ]] && output="${output} "
      
      if (( battery_percent < battery_threshold )); then
        output="${output}#[fg=${THEME[red]},bg=default,blink,bold]${icon} ${battery_percent}%${RESET}"
      else
        output="${output}${CYAN}${icon}${RESET} ${battery_percent}%"
    fi
  fi
fi

  [[ -n "$output" ]] && echo "░ ${output} "
}

main
