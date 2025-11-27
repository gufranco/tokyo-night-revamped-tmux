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
SHOW_MEMORY=$(is_widget_feature_enabled "@tokyo-night-tmux_system_memory" "1")
SHOW_DISK=$(is_widget_feature_enabled "@tokyo-night-tmux_system_disk" "1")
SHOW_BATTERY=$(is_widget_feature_enabled "@tokyo-night-tmux_system_battery" "1")

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
        disk_text="${disk_display} $(pad_percentage "$disk_percent")${COLOR_RESET}"

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
