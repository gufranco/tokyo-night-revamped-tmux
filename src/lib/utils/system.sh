#!/usr/bin/env bash

safe_divide() {
  local numerator="${1:-0}"
  local denominator="${2:-1}"
  local default="${3:-0}"

  if ! [[ "$numerator" =~ ^-?[0-9]+$ ]] || ! [[ "$denominator" =~ ^-?[0-9]+$ ]]; then
    echo "$default"
    return
  fi

  if [[ "$denominator" -eq 0 ]]; then
    echo "$default"
    return
  fi

  echo "$((numerator / denominator))"
}

clamp_value() {
  local value="${1:-0}"
  local min="${2:-0}"
  local max="${3:-100}"

  if ! [[ "$value" =~ ^-?[0-9]+$ ]] || ! [[ "$min" =~ ^-?[0-9]+$ ]] || ! [[ "$max" =~ ^-?[0-9]+$ ]]; then
    echo "0"
    return
  fi

  if [[ $min -gt $max ]]; then
    local temp=$min
    min=$max
    max=$temp
  fi

  if (( value < min )); then
    echo "$min"
  elif (( value > max )); then
    echo "$max"
  else
    echo "$value"
  fi
}

validate_percentage() {
  local value="${1:-0}"

  if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
    echo "0"
    return
  fi

  clamp_value "$value" 0 100
}

validate_positive_integer() {
  local value="${1:-0}"

  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "0"
    return
  fi

  echo "$value"
}

export -f safe_divide
export -f clamp_value
export -f validate_percentage
export -f validate_positive_integer

