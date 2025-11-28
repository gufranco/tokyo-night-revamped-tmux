#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."

if [[ -f "${LIB_DIR}/utils/error-logger.sh" ]]; then
  source "${LIB_DIR}/utils/error-logger.sh"
fi

retry_with_backoff() {
  local cmd="${1}"
  local max_attempts="${2:-3}"
  local initial_delay="${3:-1}"
  local max_delay="${4:-30}"
  local backoff_multiplier="${5:-2}"

  if [[ -z "$cmd" ]]; then
    return 1
  fi

  if ! [[ "$max_attempts" =~ ^[0-9]+$ ]] || [[ $max_attempts -lt 1 ]]; then
    max_attempts=3
  fi

  if ! [[ "$initial_delay" =~ ^[0-9]+$ ]] || [[ $initial_delay -lt 1 ]]; then
    initial_delay=1
  fi

  local delay=$initial_delay

  for ((i=1; i<=max_attempts; i++)); do
    if eval "$cmd" 2>/dev/null; then
      return 0
    fi

    if [[ $i -lt $max_attempts ]]; then
      if declare -f log_error >/dev/null 2>&1; then
        log_error "retry" "Attempt $i/$max_attempts failed for: $cmd. Retrying in ${delay}s..."
      fi

      sleep "$delay"

      delay=$((delay * backoff_multiplier))
      if [[ $delay -gt $max_delay ]]; then
        delay=$max_delay
      fi
    fi
  done

  if declare -f log_error >/dev/null 2>&1; then
    log_error "retry" "All $max_attempts attempts failed for: $cmd"
  fi

  return 1
}

retry_command() {
  local cmd="${1}"
  local max_attempts="${2:-3}"

  retry_with_backoff "$cmd" "$max_attempts" 1 5 2
}

retry_with_timeout() {
  local cmd="${1}"
  local timeout_seconds="${2:-10}"
  local max_attempts="${3:-3}"

  if [[ -z "$cmd" ]]; then
    return 1
  fi

  if ! [[ "$timeout_seconds" =~ ^[0-9]+$ ]] || [[ $timeout_seconds -lt 1 ]]; then
    timeout_seconds=10
  fi

  for ((i=1; i<=max_attempts; i++)); do
    local start_time
    start_time=$(date +%s 2>/dev/null || echo "0")

    if [[ $start_time -eq 0 ]]; then
      return 1
    fi

    if timeout "$timeout_seconds" bash -c "$cmd" 2>/dev/null; then
      return 0
    fi

    local end_time
    end_time=$(date +%s 2>/dev/null || echo "0")

    if [[ $end_time -eq 0 ]]; then
      return 1
    fi

    local elapsed=$((end_time - start_time))

    if [[ $elapsed -ge $timeout_seconds ]]; then
      if declare -f log_error >/dev/null 2>&1; then
        log_error "retry" "Command timed out after ${timeout_seconds}s: $cmd"
      fi
    fi

    if [[ $i -lt $max_attempts ]]; then
      sleep 1
    fi
  done

  return 1
}

circuit_breaker_check() {
  local service_name="${1:-}"
  local failure_threshold="${2:-5}"
  local reset_timeout="${3:-300}"

  if [[ -z "$service_name" ]]; then
    return 0
  fi

  service_name="${service_name//[^a-zA-Z0-9_-]/}"

  local breaker_dir="${HOME}/.tmux/tokyo-night-breakers"
  mkdir -p "$breaker_dir" 2>/dev/null

  local breaker_file="${breaker_dir}/${service_name}.breaker"

  if [[ ! -f "$breaker_file" ]]; then
    return 0
  fi

  if [[ ! -r "$breaker_file" ]]; then
    return 1
  fi

  local failure_count
  failure_count=$(head -1 "$breaker_file" 2>/dev/null | tr -d ' ')

  if ! [[ "$failure_count" =~ ^[0-9]+$ ]]; then
    failure_count=0
  fi

  if [[ $failure_count -ge $failure_threshold ]]; then
    local last_failure_time
    last_failure_time=$(tail -1 "$breaker_file" 2>/dev/null | tr -d ' ')

    if ! [[ "$last_failure_time" =~ ^[0-9]+$ ]]; then
      return 1
    fi

    local current_time
    current_time=$(date +%s 2>/dev/null || echo "0")

    if [[ $current_time -eq 0 ]]; then
      return 1
    fi

    local time_since_failure=$((current_time - last_failure_time))

    if [[ $time_since_failure -lt $reset_timeout ]]; then
      if declare -f log_error >/dev/null 2>&1; then
        log_error "circuit_breaker" "Circuit breaker open for $service_name (${failure_count} failures)"
      fi
      return 1
    else
      echo "0" > "$breaker_file" 2>/dev/null
      return 0
    fi
  fi

  return 0
}

circuit_breaker_record_failure() {
  local service_name="${1:-}"

  if [[ -z "$service_name" ]]; then
    return 1
  fi

  service_name="${service_name//[^a-zA-Z0-9_-]/}"

  local breaker_dir="${HOME}/.tmux/tokyo-night-breakers"
  mkdir -p "$breaker_dir" 2>/dev/null

  local breaker_file="${breaker_dir}/${service_name}.breaker"

  local failure_count=0

  if [[ -f "$breaker_file" ]] && [[ -r "$breaker_file" ]]; then
    failure_count=$(head -1 "$breaker_file" 2>/dev/null | tr -d ' ')

    if ! [[ "$failure_count" =~ ^[0-9]+$ ]]; then
      failure_count=0
    fi
  fi

  failure_count=$((failure_count + 1))

  local current_time
  current_time=$(date +%s 2>/dev/null || echo "0")

  if [[ $current_time -eq 0 ]]; then
    return 1
  fi

  if [[ -w "$breaker_dir" ]]; then
    {
      echo "$failure_count"
      echo "$current_time"
    } > "$breaker_file" 2>/dev/null
  fi

  return 0
}

circuit_breaker_reset() {
  local service_name="${1:-}"

  if [[ -z "$service_name" ]]; then
    return 1
  fi

  service_name="${service_name//[^a-zA-Z0-9_-]/}"

  local breaker_file="${HOME}/.tmux/tokyo-night-breakers/${service_name}.breaker"

  if [[ -f "$breaker_file" ]] && [[ -w "$(dirname "$breaker_file")" ]]; then
    rm -f "$breaker_file" 2>/dev/null
  fi

  return 0
}

export -f retry_with_backoff
export -f retry_command
export -f retry_with_timeout
export -f circuit_breaker_check
export -f circuit_breaker_record_failure
export -f circuit_breaker_reset

