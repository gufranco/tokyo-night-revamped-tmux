#!/usr/bin/env bash

ERROR_LOG_DIR="${HOME}/.tmux/tokyo-night-logs"
mkdir -p "$ERROR_LOG_DIR" 2>/dev/null

ERROR_LOG_FILE="${ERROR_LOG_DIR}/errors.log"
MAX_LOG_SIZE=1048576

log_error() {
  local widget_name=$1
  local error_message=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  if [[ "$(tmux show-option -gv @tokyo-night-tmux_enable_logging 2>/dev/null)" == "1" ]]; then
    echo "[${timestamp}] [${widget_name}] ${error_message}" >> "$ERROR_LOG_FILE" 2>/dev/null
    
    local log_size
    log_size=$(stat -f%z "$ERROR_LOG_FILE" 2>/dev/null || stat -c%s "$ERROR_LOG_FILE" 2>/dev/null || echo "0")
    if [[ -n "$log_size" ]] && [[ "$log_size" =~ ^[0-9]+$ ]] && [[ $log_size -gt $MAX_LOG_SIZE ]]; then
      tail -n 1000 "$ERROR_LOG_FILE" > "${ERROR_LOG_FILE}.tmp" 2>/dev/null
      mv "${ERROR_LOG_FILE}.tmp" "$ERROR_LOG_FILE" 2>/dev/null
    fi
  fi
}

log_performance() {
  local widget_name=$1
  local execution_time=$2
  
  if [[ "$(tmux show-option -gv @tokyo-night-tmux_enable_profiling 2>/dev/null)" == "1" ]]; then
    local perf_file="${ERROR_LOG_DIR}/performance.log"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${widget_name}] ${execution_time}ms" >> "$perf_file" 2>/dev/null
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

