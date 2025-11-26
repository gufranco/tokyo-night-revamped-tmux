#!/usr/bin/env bash

execute_with_timeout() {
  local timeout_seconds=${1:-5}
  local command="${@:2}"
  local result
  
  if command -v timeout >/dev/null 2>&1; then
    result=$(timeout "$timeout_seconds" bash -c "$command" 2>/dev/null)
  elif command -v gtimeout >/dev/null 2>&1; then
    result=$(gtimeout "$timeout_seconds" bash -c "$command" 2>/dev/null)
  else
    result=$(bash -c "$command" 2>/dev/null)
  fi
  
  echo "$result"
}

safe_execute() {
  local timeout_seconds=${1:-3}
  local command="${@:2}"
  local result
  
  result=$(execute_with_timeout "$timeout_seconds" "$command")
  
  if [[ -z "$result" ]]; then
    echo ""
    return 1
  fi
  
  echo "$result"
  return 0
}

export -f execute_with_timeout
export -f safe_execute

