#!/usr/bin/env bash

declare -gA PLATFORM_CACHE

has_command() {
  local cmd="${1}"

  if [[ -n "${PLATFORM_CACHE[${cmd}]}" ]]; then
    return "${PLATFORM_CACHE[${cmd}]}"
  fi

  if command -v "${cmd}" &>/dev/null; then
    PLATFORM_CACHE["${cmd}"]=0
    return 0
  else
    PLATFORM_CACHE["${cmd}"]=1
    return 1
  fi
}

export -f has_command

