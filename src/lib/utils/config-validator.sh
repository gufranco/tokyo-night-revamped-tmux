#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."

if [[ -f "${LIB_DIR}/utils/has-command.sh" ]]; then
  source "${LIB_DIR}/utils/has-command.sh"
fi

if [[ -f "${LIB_DIR}/utils/error-logger.sh" ]]; then
  source "${LIB_DIR}/utils/error-logger.sh"
fi

if [[ -f "${LIB_DIR}/utils/platform-cache.sh" ]]; then
  source "${LIB_DIR}/utils/platform-cache.sh"
fi

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
  local widget_name="${1:-}"
  local missing_deps=()

  if [[ -z "$widget_name" ]]; then
    return 1
  fi

  if ! declare -f has_command >/dev/null 2>&1; then
    has_command() {
      command -v "${1}" >/dev/null 2>&1
    }
  fi

  case "$widget_name" in
    git)
      if [[ "$(tmux show-option -gv @tokyo-night-tmux_git_web 2>/dev/null)" == "1" ]]; then
        if ! has_command gh && ! has_command glab; then
          missing_deps+=("gh or glab")
        fi
        if ! has_command jq; then
          missing_deps+=("jq")
        fi
      fi
      ;;
    docker)
      if ! has_command docker; then
        missing_deps+=("docker")
      fi
      if [[ "$(tmux show-option -gv @tokyo-night-tmux_docker_kubernetes 2>/dev/null)" == "1" ]]; then
        if ! has_command kubectl; then
          missing_deps+=("kubectl")
        fi
      fi
      ;;
    context)
      if [[ "$(tmux show-option -gv @tokyo-night-tmux_context_weather 2>/dev/null)" == "1" ]]; then
        if ! has_command curl && ! has_command wget; then
          missing_deps+=("curl or wget")
        fi
      fi
      ;;
    system)
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

