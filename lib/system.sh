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

command_exists() {
  command -v "${1}" >/dev/null 2>&1
}

require_command() {
  local cmd="${1}"

  if ! command_exists "${cmd}"; then
    return 1
  fi

  return 0
}

check_required_command() {
  local cmd="${1}"
  local install_msg="${2}"

  if ! command_exists "${cmd}"; then
    echo "#[fg=#e0af68]⚠ Widget requires '${cmd}'. Install: ${install_msg} "
    return 1
  fi

  return 0
}

check_any_command() {
  local cmd1="${1}"
  local cmd2="${2}"

  if ! command_exists "${cmd1}" && ! command_exists "${cmd2}"; then
    return 1
  fi

  return 0
}

export -f safe_divide
export -f clamp_value
export -f command_exists
export -f require_command
export -f check_required_command
export -f check_any_command

