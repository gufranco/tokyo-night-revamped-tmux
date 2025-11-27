#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/widget/widget-loader.sh"
source "${LIB_DIR}/tmux/tmux-ops.sh"
source "${LIB_DIR}/widget/widget-common.sh"
source "${LIB_DIR}/widget/widget-config.sh"

load_widget_dependencies "system"

validate_widget_enabled "@tokyo-night-tmux_show_system"

cached_output=$(get_cached_widget_output "system")
should_use_cache "$cached_output" && echo "$cached_output" && exit 0

SHOW_CPU=$(is_widget_feature_enabled "@tokyo-night-tmux_system_cpu" "1")
SHOW_LOAD=$(is_widget_feature_enabled "@tokyo-night-tmux_system_load" "1")
SHOW_GPU=$(is_widget_feature_enabled "@tokyo-night-tmux_system_gpu" "1")
SHOW_MEMORY=$(is_widget_feature_enabled "@tokyo-night-tmux_system_memory" "1")
SHOW_SWAP=$(is_widget_feature_enabled "@tokyo-night-tmux_system_swap" "1")
SHOW_DISK=$(is_widget_feature_enabled "@tokyo-night-tmux_system_disk" "1")
SHOW_BATTERY=$(is_widget_feature_enabled "@tokyo-night-tmux_system_battery" "1")
SHOW_TEMP=$(is_widget_feature_enabled "@tokyo-night-tmux_system_temp" "0")
SHOW_UPTIME=$(is_widget_feature_enabled "@tokyo-night-tmux_system_uptime" "0")
SHOW_DISK_IO=$(is_widget_feature_enabled "@tokyo-night-tmux_system_disk_io" "0")
SHOW_HEALTH=$(is_widget_feature_enabled "@tokyo-night-tmux_system_health" "0")
SHOW_FREQUENCY=$(is_widget_feature_enabled "@tokyo-night-tmux_system_frequency" "0")
SHOW_PRESSURE=$(is_widget_feature_enabled "@tokyo-night-tmux_system_pressure" "0")
SHOW_DISK_SPACE=$(is_widget_feature_enabled "@tokyo-night-tmux_system_disk_space" "0")
SHOW_CONNECTIONS=$(is_widget_feature_enabled "@tokyo-night-tmux_system_connections" "0")

WIDGET_THRESHOLD_CRITICAL=$(get_widget_threshold "@tokyo-night-tmux_threshold_critical" "80")
WIDGET_THRESHOLD_WARNING=$(get_widget_threshold "@tokyo-night-tmux_threshold_warning" "50")
WIDGET_WIDGET_THRESHOLD_HIGH=$(get_widget_threshold "@tokyo-night-tmux_threshold_high" "75")

get_cpu_color_and_icon() {
  local usage=$1
  local icon
  local color

  if (( usage >= WIDGET_THRESHOLD_CRITICAL )); then
    color="${COLOR_RED}"
  elif (( usage >= WIDGET_THRESHOLD_WARNING )); then
    color="${COLOR_YELLOW}"
  else
    color="${COLOR_CYAN}"
  fi

  local idx=$(( usage / 10 ))
  (( idx > 10 )) && idx=10
  icon="${CPU_ICONS[$idx]}"

  echo "${color}${icon}"
}

get_gpu_color_and_icon() {
  local usage=$1
  local icon
  local color

  if (( usage >= WIDGET_THRESHOLD_CRITICAL )); then
    color="${COLOR_RED}"
  elif (( usage >= WIDGET_THRESHOLD_WARNING )); then
    color="${COLOR_YELLOW}"
  else
    color="${COLOR_CYAN}"
  fi

  local idx=$(( usage / 10 ))
  (( idx > 10 )) && idx=10
  icon="${GPU_ICONS[$idx]}"

  echo "${color}${icon}"
}

get_memory_color_and_icon() {
  local usage=$1
  local icon
  local color

  if (( usage >= WIDGET_THRESHOLD_CRITICAL )); then
    color="${COLOR_RED}"
  elif (( usage >= WIDGET_THRESHOLD_WARNING )); then
    color="${COLOR_YELLOW}"
  else
    color="${COLOR_CYAN}"
  fi

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

  if [[ $SHOW_GPU -eq 1 ]]; then
    local gpu_usage gpu_display

    if is_apple_silicon; then
      gpu_usage=$(get_gpu_usage_percentage)
    elif is_linux; then
      gpu_usage=$(get_gpu_usage_percentage)
    else
      gpu_usage=0
    fi

    if [[ -n "$gpu_usage" ]] && [[ "$gpu_usage" =~ ^[0-9]+$ ]] && [[ $gpu_usage -gt 0 ]]; then
      gpu_usage=$(validate_percentage "$gpu_usage")
      gpu_display=$(get_gpu_color_and_icon "$gpu_usage")
      [[ -n "$output" ]] && output="${output} "
      output="${output}${gpu_display} $(pad_percentage "$gpu_usage")${COLOR_RESET}"
    fi
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
    local multiple_disks
    multiple_disks=$(tmux show-option -gv @tokyo-night-tmux_system_multiple_disks 2>/dev/null)
    multiple_disks="${multiple_disks:-0}"

    if [[ $multiple_disks -eq 1 ]]; then
      local disks_list
      disks_list=$(get_multiple_disks)
      if [[ -n "$disks_list" ]]; then
        local disk_count=0
        local max_disks=3
        for disk_info in $disks_list; do
          if [[ $disk_count -ge $max_disks ]]; then
            break
          fi
          IFS=':' read -r device mount usage <<< "$disk_info"
          usage="${usage//%/}"
          usage=$(validate_percentage "$usage")
          local disk_display
          disk_display=$(get_disk_color_and_icon "$usage")
          local mount_name
          mount_name=$(basename "$mount" 2>/dev/null || echo "$mount")
          mount_name="${mount_name:0:8}"
          [[ -n "$output" ]] && output="${output} "
          output="${output}${disk_display} ${mount_name}:$(pad_percentage "$usage")${COLOR_RESET}"
          ((disk_count++))
        done
      fi
    else
      local disk_path disk_percent disk_display
      disk_path=$(tmux show-option -gv @tokyo-night-tmux_system_disk_path 2>/dev/null)
      disk_path="${disk_path:-/}"
      disk_percent=$(df -h "$disk_path" 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5}')

      if [[ -n "$disk_percent" ]]; then
        disk_percent=$(validate_percentage "$disk_percent")
        disk_display=$(get_disk_color_and_icon "$disk_percent")

        local disk_text
        if [[ $SHOW_DISK_SPACE -eq 1 ]]; then
          local disk_space
          disk_space=$(get_disk_space_gb "$disk_path")
          read -r total_gb used_gb free_gb <<< "$disk_space"
          if [[ -n "$total_gb" ]] && [[ "$total_gb" =~ ^[0-9]+$ ]] && [[ $total_gb -gt 0 ]]; then
            local formatted_space
            formatted_space=$(format_compact_value "$used_gb" "GB")
            local formatted_total
            formatted_total=$(format_compact_value "$total_gb" "GB")
            disk_text="${disk_display} ${formatted_space}/${formatted_total} ($(pad_percentage "$disk_percent"))${COLOR_RESET}"
          else
            disk_text="${disk_display} $(pad_percentage "$disk_percent")${COLOR_RESET}"
          fi
        else
          disk_text="${disk_display} $(pad_percentage "$disk_percent")${COLOR_RESET}"
        fi

        [[ -n "$output" ]] && output="${output} "
        output="${output}${disk_text}"
      fi
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
            local red_color_value
            red_color_value=$(get_color_red)
            color="#[fg=${red_color_value},bg=default,blink,bold]"
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

  if [[ $SHOW_TEMP -eq 1 ]]; then
    local cpu_temp gpu_temp temp_display
    cpu_temp=$(get_cpu_temperature)
    gpu_temp=$(get_gpu_temperature)

    if [[ -n "$cpu_temp" ]] && [[ "$cpu_temp" =~ ^[0-9]+$ ]] && [[ $cpu_temp -gt 0 ]]; then
      local temp_color
      if (( cpu_temp >= 80 )); then
        temp_color="${COLOR_RED}"
      elif (( cpu_temp >= 60 )); then
        temp_color="${COLOR_YELLOW}"
      else
        temp_color="${COLOR_CYAN}"
      fi

      [[ -n "$output" ]] && output="${output} "
      output="${output}${temp_color}${ICON_TEMPERATURE} ${cpu_temp}°C${COLOR_RESET}"

      if [[ -n "$gpu_temp" ]] && [[ "$gpu_temp" =~ ^[0-9]+$ ]] && [[ $gpu_temp -gt 0 ]] && [[ $gpu_temp -ne $cpu_temp ]]; then
        if (( gpu_temp >= 80 )); then
          temp_color="${COLOR_RED}"
        elif (( gpu_temp >= 60 )); then
          temp_color="${COLOR_YELLOW}"
        else
          temp_color="${COLOR_CYAN}"
        fi
        output="${output} ${temp_color}${ICON_TEMPERATURE} ${gpu_temp}°C${COLOR_RESET}"
      fi
    fi
  fi

  if [[ $SHOW_UPTIME -eq 1 ]]; then
    local uptime_seconds uptime_formatted
    uptime_seconds=$(get_system_uptime)
    if [[ -n "$uptime_seconds" ]] && [[ "$uptime_seconds" =~ ^[0-9]+$ ]] && [[ $uptime_seconds -gt 0 ]]; then
      uptime_formatted=$(format_uptime "$uptime_seconds")
      [[ -n "$output" ]] && output="${output} "
      output="${output}${COLOR_CYAN}${ICON_UPTIME} ${uptime_formatted}${COLOR_RESET}"
    fi
  fi

  if [[ $SHOW_DISK_IO -eq 1 ]]; then
    local disk_io read_kb write_kb
    disk_io=$(get_disk_io)
    read -r read_kb write_kb <<< "$disk_io"

    if [[ -n "$read_kb" ]] && [[ "$read_kb" =~ ^[0-9]+$ ]] && [[ $read_kb -gt 0 ]]; then
      local io_color
      if (( read_kb + write_kb > 100000 )); then
        io_color="${COLOR_RED}"
      elif (( read_kb + write_kb > 50000 )); then
        io_color="${COLOR_YELLOW}"
      else
        io_color="${COLOR_CYAN}"
      fi

      [[ -n "$output" ]] && output="${output} "
      output="${output}${io_color}${ICON_DISK_IO} R:${read_kb}KB W:${write_kb}KB${COLOR_RESET}"
    fi
  fi

  if [[ $SHOW_HEALTH -eq 1 ]]; then
    local health_status health_issues health_icon health_color
    health_status=$(get_system_health_status)
    IFS='|' read -r health_state health_issues <<< "$health_status"

    case "$health_state" in
      critical)
        health_icon="${ICON_HEALTH_CRITICAL}"
        health_color="${COLOR_RED}"
        ;;
      warning)
        health_icon="${ICON_HEALTH_WARNING}"
        health_color="${COLOR_YELLOW}"
        ;;
      *)
        health_icon="${ICON_HEALTH_OK}"
        health_color="${COLOR_GREEN}"
        ;;
    esac

    [[ -n "$output" ]] && output="${output} "
    output="${output}${health_color}${health_icon}${COLOR_RESET}"
  fi

  if [[ $SHOW_FREQUENCY -eq 1 ]]; then
    local cpu_freq
    cpu_freq=$(get_cpu_frequency)
    if [[ -n "$cpu_freq" ]] && [[ "$cpu_freq" =~ ^[0-9]+$ ]] && [[ $cpu_freq -gt 0 ]]; then
      [[ -n "$output" ]] && output="${output} "
      output="${output}${COLOR_CYAN}${ICON_FREQUENCY} ${cpu_freq}GHz${COLOR_RESET}"
    fi
  fi

  if [[ $SHOW_PRESSURE -eq 1 ]]; then
    local mem_pressure
    mem_pressure=$(get_memory_pressure)
    if [[ -n "$mem_pressure" ]] && [[ "$mem_pressure" =~ ^[0-9]+$ ]]; then
      local pressure_color
      if (( mem_pressure < 20 )); then
        pressure_color="${COLOR_RED}"
      elif (( mem_pressure < 40 )); then
        pressure_color="${COLOR_YELLOW}"
      else
        pressure_color="${COLOR_CYAN}"
      fi
      [[ -n "$output" ]] && output="${output} "
      output="${output}${pressure_color}${ICON_PRESSURE} ${mem_pressure}%${COLOR_RESET}"
    fi
  fi

  if [[ $SHOW_CONNECTIONS -eq 1 ]]; then
    local connections
    connections=$(get_network_connections)
    if [[ -n "$connections" ]] && [[ "$connections" =~ ^[0-9]+$ ]] && [[ $connections -gt 0 ]]; then
      local conn_color
      if (( connections >= 1000 )); then
        conn_color="${COLOR_RED}"
      elif (( connections >= 500 )); then
        conn_color="${COLOR_YELLOW}"
      else
        conn_color="${COLOR_CYAN}"
      fi
      [[ -n "$output" ]] && output="${output} "
      output="${output}${conn_color}${ICON_CONNECTIONS} ${connections}${COLOR_RESET}"
    fi
  fi

  if [[ -n "$output" ]]; then
    local tooltip_text
    tooltip_text=$(generate_system_tooltip)
    set_widget_tooltip "system" "$tooltip_text"

    local result="${COLOR_CYAN}░${COLOR_RESET} ${output} "
    set_cached_value "system" "$result"
    echo "$result"
  fi
}

main
