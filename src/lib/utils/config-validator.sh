#!/usr/bin/env bash

validate_config() {
  local errors=0
  local warnings=0
  
  if ! declare -f log_error >/dev/null 2>&1; then
    log_error() {
      :
    }
  fi
  
  local refresh_rate
  refresh_rate=$(tmux show-option -gv @tokyo-night-tmux_refresh_rate 2>/dev/null)
  if [[ -n "$refresh_rate" ]] && [[ ! "$refresh_rate" =~ ^[0-9]+$ ]]; then
    log_error "config" "Invalid refresh_rate: ${refresh_rate} (must be a number)"
    ((errors++))
  elif [[ -n "$refresh_rate" ]] && (( refresh_rate < 1 )); then
    log_error "config" "Invalid refresh_rate: ${refresh_rate} (must be >= 1)"
    ((errors++))
  fi
  
  local widgets_order
  widgets_order=$(tmux show-option -gv @tokyo-night-tmux_widgets_order 2>/dev/null)
  if [[ -n "$widgets_order" ]]; then
    local valid_widgets="system git netspeed context process docker"
    IFS=',' read -ra widgets <<< "$widgets_order"
    for widget in "${widgets[@]}"; do
      widget="${widget// /}"
      if [[ ! "$valid_widgets" =~ $widget ]]; then
        log_error "config" "Invalid widget in order: ${widget}"
        ((errors++))
      fi
    done
  fi
  
  local date_format
  date_format=$(tmux show-option -gv @tokyo-night-tmux_context_date_format 2>/dev/null)
  if [[ -n "$date_format" ]] && [[ ! "$date_format" =~ ^(YMD|MDY|DMY|hide)$ ]]; then
    log_error "config" "Invalid date_format: ${date_format}"
    ((errors++))
  fi
  
  local time_format
  time_format=$(tmux show-option -gv @tokyo-night-tmux_context_time_format 2>/dev/null)
  if [[ -n "$time_format" ]] && [[ ! "$time_format" =~ ^(24H|12H|hide)$ ]]; then
    log_error "config" "Invalid time_format: ${time_format}"
    ((errors++))
  fi
  
  if [[ $errors -eq 0 ]] && [[ $warnings -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

check_dependencies() {
  local widget_name=$1
  local missing_deps=()
  
  case "$widget_name" in
    git)
      if [[ "$(tmux show-option -gv @tokyo-night-tmux_git_web 2>/dev/null)" == "1" ]]; then
        command -v gh >/dev/null 2>&1 || command -v glab >/dev/null 2>&1 || missing_deps+=("gh or glab")
        command -v jq >/dev/null 2>&1 || missing_deps+=("jq")
      fi
      ;;
    docker)
      command -v docker >/dev/null 2>&1 || missing_deps+=("docker")
      if [[ "$(tmux show-option -gv @tokyo-night-tmux_docker_kubernetes 2>/dev/null)" == "1" ]]; then
        command -v kubectl >/dev/null 2>&1 || missing_deps+=("kubectl")
      fi
      ;;
    context)
      if [[ "$(tmux show-option -gv @tokyo-night-tmux_context_weather 2>/dev/null)" == "1" ]]; then
        command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || missing_deps+=("curl or wget")
      fi
      ;;
    system)
      if [[ "$(tmux show-option -gv @tokyo-night-tmux_system_temp 2>/dev/null)" == "1" ]]; then
        if is_macos; then
          command -v istats >/dev/null 2>&1 || missing_deps+=("istats (optional)")
        else
          [[ ! -d /sys/class/thermal ]] && command -v sensors >/dev/null 2>&1 || missing_deps+=("sensors (optional)")
        fi
      fi
      ;;
  esac
  
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo "${missing_deps[*]}"
    return 1
  fi
  
  return 0
}

export -f validate_config
export -f check_dependencies

