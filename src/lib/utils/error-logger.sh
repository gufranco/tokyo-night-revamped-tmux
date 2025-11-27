#!/usr/bin/env bash

ERROR_LOG_DIR="${ERROR_LOG_DIR:-${HOME}/.tmux/tokyo-night-logs}"
ERROR_LOG_FILE="${ERROR_LOG_FILE:-${ERROR_LOG_DIR}/errors.log}"
MAX_LOG_SIZE="${MAX_LOG_SIZE:-1048576}"
MAX_LOG_LINES="${MAX_LOG_LINES:-1000}"

mkdir -p "$ERROR_LOG_DIR" 2>/dev/null

log_error() {
  local widget_name="${1:-unknown}"
  local error_message="${2:-}"

  if [[ -z "$error_message" ]]; then
    return 0
  fi

  widget_name="${widget_name//[^a-zA-Z0-9_-]/}"

  if [[ "$(tmux show-option -gv @tokyo-night-tmux_enable_logging 2>/dev/null)" == "1" ]]; then
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "")

    if [[ -n "$timestamp" ]] && [[ -w "$ERROR_LOG_DIR" ]] 2>/dev/null; then
      echo "[${timestamp}] [${widget_name}] ${error_message}" >> "$ERROR_LOG_FILE" 2>/dev/null

      if [[ -f "$ERROR_LOG_FILE" ]]; then
        local log_size
        log_size=$(stat -f%z "$ERROR_LOG_FILE" 2>/dev/null || stat -c%s "$ERROR_LOG_FILE" 2>/dev/null || echo "0")
        if [[ -n "$log_size" ]] && [[ "$log_size" =~ ^[0-9]+$ ]] && [[ $log_size -gt $MAX_LOG_SIZE ]]; then
          tail -n $MAX_LOG_LINES "$ERROR_LOG_FILE" > "${ERROR_LOG_FILE}.tmp" 2>/dev/null
          mv "${ERROR_LOG_FILE}.tmp" "$ERROR_LOG_FILE" 2>/dev/null
        fi
      fi
    fi
  fi
}

log_performance() {
  local widget_name="${1:-unknown}"
  local execution_time="${2:-0}"

  if [[ ! "$execution_time" =~ ^[0-9]+$ ]] || [[ $execution_time -lt 0 ]]; then
    return 0
  fi

  widget_name="${widget_name//[^a-zA-Z0-9_-]/}"

  if [[ "$(tmux show-option -gv @tokyo-night-tmux_enable_profiling 2>/dev/null)" == "1" ]]; then
    local perf_file="${ERROR_LOG_DIR}/performance.log"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "")

    if [[ -n "$timestamp" ]] && [[ -w "$ERROR_LOG_DIR" ]] 2>/dev/null; then
      echo "[${timestamp}] [${widget_name}] ${execution_time}ms" >> "$perf_file" 2>/dev/null
    fi
  fi
}

profile_widget() {
  local widget_name=$1
  local start_time
  start_time=$(date +%s%N)

  "$@"
  local exit_code=$?

  local end_time
  end_time=$(date +%s%N)
  local execution_time
  execution_time=$(( (end_time - start_time) / 1000000 ))

  log_performance "$widget_name" "$execution_time"

  return $exit_code
}

export -f log_error
export -f log_performance

