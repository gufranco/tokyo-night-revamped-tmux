#!/usr/bin/env bash

safe_divide() {
  local numerator="${1}"
  local denominator="${2}"
  local default="${3:-0}"

  if [[ "${denominator}" -eq 0 ]]; then
    echo "${default}"
    return
  fi

  echo "$((numerator / denominator))"
}

clamp_value() {
  local value="${1}"
  local min="${2}"
  local max="${3}"

  if (( value < min )); then
    echo "${min}"
  elif (( value > max )); then
    echo "${max}"
  else
    echo "${value}"
  fi
}

export -f safe_divide
export -f clamp_value

