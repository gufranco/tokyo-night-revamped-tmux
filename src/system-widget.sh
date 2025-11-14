#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${LIB_DIR}/platform-detector.sh"
source "${LIB_DIR}/themes.sh"
source "${LIB_DIR}/color-scale.sh"
source "${LIB_DIR}/cache.sh"
source "${LIB_DIR}/format.sh"

is_widget_enabled "@tokyo-night-tmux_show_system" || exit 0

REFRESH_RATE=$(get_refresh_rate)
CACHED=$(get_cached_value "system" "$REFRESH_RATE")

if [[ -n "$CACHED" ]]; then
  echo "$CACHED"
  exit 0
fi

SHOW_CPU=$(tmux show-option -gv @tokyo-night-tmux_system_cpu 2>/dev/null)
SHOW_LOAD=$(tmux show-option -gv @tokyo-night-tmux_system_load 2>/dev/null)
SHOW_GPU=$(tmux show-option -gv @tokyo-night-tmux_system_gpu 2>/dev/null)
SHOW_MEMORY=$(tmux show-option -gv @tokyo-night-tmux_system_memory 2>/dev/null)
SHOW_SWAP=$(tmux show-option -gv @tokyo-night-tmux_system_swap 2>/dev/null)
SHOW_DISK=$(tmux show-option -gv @tokyo-night-tmux_system_disk 2>/dev/null)
SHOW_BATTERY=$(tmux show-option -gv @tokyo-night-tmux_system_battery 2>/dev/null)

SHOW_CPU="${SHOW_CPU:-1}"
SHOW_LOAD="${SHOW_LOAD:-1}"
SHOW_GPU="${SHOW_GPU:-1}"
SHOW_MEMORY="${SHOW_MEMORY:-1}"
SHOW_SWAP="${SHOW_SWAP:-1}"
SHOW_DISK="${SHOW_DISK:-1}"
SHOW_BATTERY="${SHOW_BATTERY:-1}"

get_cpu_color_and_icon() {
  local usage=$1
  local icon
  local color=$(get_system_color "$usage")
  
  local idx=$(( usage / 10 ))
  (( idx > 10 )) && idx=10
  icon="${CPU_ICONS[$idx]}"
  
  echo "${color}${icon}"
}

get_gpu_color_and_icon() {
  local usage=$1
  local icon
  local color=$(get_system_color "$usage")
  
  local idx=$(( usage / 10 ))
  (( idx > 10 )) && idx=10
  icon="${GPU_ICONS[$idx]}"
  
  echo "${color}${icon}"
}

get_memory_color_and_icon() {
  local usage=$1
  local icon
  local color=$(get_system_color "$usage")
  
  local idx=$(( usage / 10 ))
  (( idx > 10 )) && idx=10
  icon="${MEMORY_ICONS[$idx]}"
  
  echo "${color}${icon}"
}

get_load_color_and_icon() {
  local usage=$1
  local icon
  local color=$(get_system_color "$usage")
  
  local idx=$(( usage / 10 ))
  (( idx > 10 )) && idx=10
  icon="${LOAD_ICONS[$idx]}"
  
  echo "${color}${icon}"
}

get_swap_color_and_icon() {
  local usage=$1
  local icon
  local color=$(get_system_color "$usage")
  
  local idx=$(( usage / 10 ))
  (( idx > 10 )) && idx=10
  icon="${SWAP_ICONS[$idx]}"
  
  echo "${color}${icon}"
}

get_disk_color_and_icon() {
  local usage=$1
  local icon
  local color=$(get_system_color "$usage")
  
  local idx=$(( usage / 10 ))
  (( idx > 10 )) && idx=10
  icon="${DISK_ICONS[$idx]}"
  
  echo "${color}${icon}"
}

main() {
  local output=""
  
  if [[ $SHOW_CPU -eq 1 ]]; then
    local cpu_usage cpu_display
    cpu_usage=$(get_cpu_usage_percentage)
    cpu_usage=$(validate_percentage "$cpu_usage")
    cpu_display=$(get_cpu_color_and_icon "$cpu_usage")
    output="${cpu_display} $(pad_percentage "$cpu_usage")${COLOR_RESET}"
  fi

  if [[ $SHOW_LOAD -eq 1 ]]; then
    local load_avg cpu_count load_display load_percent
    load_avg=$(get_load_average)
    cpu_count=$(get_cpu_count)
    
    if [[ -n "$load_avg" ]] && [[ -n "$cpu_count" ]] && [[ "$cpu_count" -gt 0 ]]; then
      load_avg="${load_avg//,/.}"
      
      load_percent=$(awk "BEGIN {printf \"%.0f\", ($load_avg / $cpu_count) * 100}")
      
      load_percent=$(validate_percentage "$load_percent")
      load_display=$(get_load_color_and_icon "$load_percent")
      
      [[ -n "$output" ]] && output="${output} "
      output="${output}${load_display} $(pad_percentage "$load_percent")${COLOR_RESET}"
    fi
  fi

  if [[ $SHOW_GPU -eq 1 ]] && is_apple_silicon; then
    local gpu_usage gpu_display
    
    gpu_usage=$(ioreg -r -d 1 -w 0 -c "IOAccelerator" 2>/dev/null | grep -o '"Device Utilization %"=[0-9]*' | sed 's/.*=//' | head -1)
    
    if [[ -z "$gpu_usage" ]] || [[ ! "$gpu_usage" =~ ^[0-9]+$ ]]; then
      local windowserver_cpu
      windowserver_cpu=$(ps axo %cpu,command 2>/dev/null | awk '/WindowServer/ && /-daemon/ {cpu=$1; gsub(/,/, ".", cpu); cpu_num=cpu+0; if (cpu_num > 0) print int(cpu_num); exit}')
      
      if [[ -n "$windowserver_cpu" ]] && [[ "$windowserver_cpu" =~ ^[0-9]+$ ]] && [[ $windowserver_cpu -gt 0 ]]; then
        if [[ $windowserver_cpu -le 3 ]]; then
          gpu_usage=$(( windowserver_cpu * 2 ))
        elif [[ $windowserver_cpu -le 10 ]]; then
          gpu_usage=$(( windowserver_cpu * 3 ))
        elif [[ $windowserver_cpu -le 25 ]]; then
          gpu_usage=$(( windowserver_cpu * 4 ))
        elif [[ $windowserver_cpu -le 40 ]]; then
          gpu_usage=$(( windowserver_cpu * 5 ))
        else
          gpu_usage=$(( windowserver_cpu * 6 ))
        fi
        (( gpu_usage > 100 )) && gpu_usage=100
        (( gpu_usage < 1 )) && gpu_usage=1
      else
        gpu_usage=1
      fi
    else
      (( gpu_usage > 100 )) && gpu_usage=100
      (( gpu_usage < 1 )) && gpu_usage=1
    fi
    
    gpu_display=$(get_gpu_color_and_icon "$gpu_usage")
    [[ -n "$output" ]] && output="${output} "
    output="${output}${gpu_display} $(pad_percentage "$gpu_usage")${COLOR_RESET}"
  fi
  
  if [[ $SHOW_MEMORY -eq 1 ]]; then
    local mem_total mem_used mem_percent mem_display
  
    if is_macos; then
      mem_total=$(sysctl -n hw.memsize 2>/dev/null)
      local page_size pages_wired pages_compressed
      page_size=$(pagesize 2>/dev/null || sysctl -n hw.pagesize 2>/dev/null)
      
      read -r pages_wired pages_compressed < <(vm_stat 2>/dev/null | awk '
        /Pages wired down/ {gsub(/\./, "", $NF); wired=$NF}
        /Pages occupied by compressor/ {gsub(/\./, "", $NF); compressed=$NF}
        END {print wired, compressed}
      ')
      
      mem_used=$(( (pages_wired + pages_compressed) * page_size ))
      mem_percent=$(( (mem_used * 100) / mem_total ))
    else
      read -r mem_total mem_available < <(awk '
        /MemTotal/ {total=$2 * 1024}
        /MemAvailable/ {available=$2 * 1024}
        END {print total, available}
      ' /proc/meminfo 2>/dev/null)
      
      mem_used=$(( mem_total - mem_available ))
      mem_percent=$(( (mem_used * 100) / mem_total ))
    fi
    
    mem_percent=$(validate_percentage "$mem_percent")
    mem_display=$(get_memory_color_and_icon "$mem_percent")
  
    [[ -n "$output" ]] && output="${output} "
    output="${output}${mem_display} $(pad_percentage "$mem_percent")${COLOR_RESET}"
  fi
  
  if [[ $SHOW_SWAP -eq 1 ]]; then
    local swap_total swap_used swap_percent swap_display
    
    if is_macos; then
      read -r swap_total swap_used < <(sysctl -n vm.swapusage 2>/dev/null | awk '{
        gsub(/[,M]/, "", $3); total=$3
        gsub(/[,M]/, "", $6); used=$6
        print total, used
      }')
      
      if [[ -n "$swap_total" ]] && [[ "$swap_total" =~ ^[0-9]+$ ]] && (( swap_total > 0 )); then
        swap_percent=$(( (swap_used * 100) / swap_total ))
        swap_percent=$(validate_percentage "$swap_percent")
        swap_display=$(get_swap_color_and_icon "$swap_percent")
        
        [[ -n "$output" ]] && output="${output} "
        output="${output}${swap_display} $(pad_percentage "$swap_percent")${COLOR_RESET}"
      fi
    else
      if command -v free >/dev/null 2>&1; then
        read -r swap_total swap_used < <(free | awk '/Swap:/ {print $2, $3}')
    
        if [[ -n "$swap_total" ]] && [[ "$swap_total" =~ ^[0-9]+$ ]] && (( swap_total > 0 )); then
          swap_percent=$(( (swap_used * 100) / swap_total ))
          swap_percent=$(validate_percentage "$swap_percent")
          swap_display=$(get_swap_color_and_icon "$swap_percent")
          
          [[ -n "$output" ]] && output="${output} "
          output="${output}${swap_display} $(pad_percentage "$swap_percent")${COLOR_RESET}"
        fi
      fi
    fi
  fi

  if [[ $SHOW_DISK -eq 1 ]]; then
    local disk_path disk_percent disk_display
    disk_path=$(tmux show-option -gv @tokyo-night-tmux_system_disk_path 2>/dev/null)
    disk_path="${disk_path:-/}"
    disk_percent=$(df -h "$disk_path" 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5}')
  
    if [[ -n "$disk_percent" ]]; then
      disk_percent=$(validate_percentage "$disk_percent")
      disk_display=$(get_disk_color_and_icon "$disk_percent")
      
      [[ -n "$output" ]] && output="${output} "
      output="${output}${disk_display} $(pad_percentage "$disk_percent")${COLOR_RESET}"
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
        read -r battery_status battery_percent < <(pmset -g batt 2>/dev/null | awk -v name="$battery_name" '
          NR==1 {ac=(/AC Power/ ? 1 : 0)}
          $0 ~ name {
            gsub(/[^0-9]/, "", $3)
            gsub(/[^a-zA-Z]/, "", $4)
            if (ac) print "charging", $3
            else print $4, $3
          }
        ')
      else
        battery_status=$(<"/sys/class/power_supply/${battery_name}/status")
        battery_percent=$(<"/sys/class/power_supply/${battery_name}/capacity")
      fi
      
      battery_percent=$(validate_percentage "$battery_percent")
      
      local status_lower="${battery_status,,}"
      
      case "${status_lower}" in
        charging|charged|full|ac)
          icon="${ICON_BATTERY_PLUG}"
          color="${COLOR_CYAN}"
          ;;
        discharging)
          local idx=$(( battery_percent / 10 ))
          (( idx > 10 )) && idx=10
          icon="${BATTERY_ICONS[$idx]}"
          
          if (( battery_percent < battery_threshold )); then
            color="#[fg=${THEME[red]},bg=default,blink,bold]"
          elif (( battery_percent < 30 )); then
            color="${COLOR_YELLOW}"
          else
            color="${COLOR_CYAN}"
          fi
          ;;
        *)
          icon="${ICON_BATTERY_NO}"
          color="${COLOR_CYAN}"
          ;;
      esac
      
      [[ -n "$output" ]] && output="${output} "
      output="${output}${color}${icon} $(pad_percentage "$battery_percent")${COLOR_RESET}"
    fi
  fi

  if [[ -n "$output" ]]; then
    local result="${COLOR_CYAN}░${COLOR_RESET} ${output} "
    set_cached_value "system" "$result"
    echo "$result"
  fi
}

main
