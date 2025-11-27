#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."

if [[ -f "${LIB_DIR}/utils/error-logger.sh" ]]; then
  source "${LIB_DIR}/utils/error-logger.sh"
fi

check_widget_health() {
  local widget_name="${1:-}"
  local max_execution_time="${2:-5000}"
  
  if [[ -z "$widget_name" ]]; then
    return 1
  fi
  
  widget_name="${widget_name//[^a-zA-Z0-9_-]/}"
  
  local widget_script="${LIB_DIR}/../${widget_name}-widget.sh"
  
  if [[ ! -f "$widget_script" ]] || [[ ! -x "$widget_script" ]]; then
    log_error "health" "Widget script not found or not executable: ${widget_name}"
    return 1
  fi
  
  local start_time
  start_time=$(date +%s%N 2>/dev/null || echo "0")
  
  if [[ $start_time -eq 0 ]]; then
    return 1
  fi
  
  bash "$widget_script" >/dev/null 2>&1
  local exit_code=$?
  
  local end_time
  end_time=$(date +%s%N 2>/dev/null || echo "0")
  
  if [[ $end_time -eq 0 ]]; then
    return 1
  fi
  
  local execution_time
  execution_time=$(( (end_time - start_time) / 1000000 ))
  
  if [[ $exit_code -ne 0 ]]; then
    log_error "health" "Widget ${widget_name} failed with exit code ${exit_code}"
    return 1
  fi
  
  if [[ $execution_time -gt $max_execution_time ]]; then
    log_error "health" "Widget ${widget_name} exceeded max execution time: ${execution_time}ms > ${max_execution_time}ms"
    return 1
  fi
  
  return 0
}

check_system_resources() {
  local cpu_threshold="${1:-90}"
  local mem_threshold="${2:-90}"
  
  if ! [[ "$cpu_threshold" =~ ^[0-9]+$ ]] || ! [[ "$mem_threshold" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  
  if [[ -f "${LIB_DIR}/platform-detector.sh" ]]; then
    source "${LIB_DIR}/platform-detector.sh"
  fi
  
  if [[ -f "${LIB_DIR}/cpu/cpu.sh" ]]; then
    source "${LIB_DIR}/cpu/cpu.sh"
  fi
  
  if [[ -f "${LIB_DIR}/ram/ram.sh" ]]; then
    source "${LIB_DIR}/ram/ram.sh"
  fi
  
  local cpu_usage
  cpu_usage=$(get_cpu_usage_percentage 2>/dev/null || echo "0")
  
  local mem_total mem_active mem_usage
  mem_total=$(get_total_memory_kb 2>/dev/null || echo "0")
  mem_active=$(get_active_memory_kb 2>/dev/null || echo "0")
  
  if [[ $mem_total -gt 0 ]]; then
    mem_usage=$(( (mem_active * 100) / mem_total ))
  else
    mem_usage=0
  fi
  
  if [[ $cpu_usage -gt $cpu_threshold ]] || [[ $mem_usage -gt $mem_threshold ]]; then
    log_error "health" "System resources high: CPU=${cpu_usage}% MEM=${mem_usage}%"
    return 1
  fi
  
  return 0
}

export -f check_widget_health
export -f check_system_resources

