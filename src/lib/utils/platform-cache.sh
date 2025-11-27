#!/usr/bin/env bash

declare -gA PLATFORM_CACHE

init_platform_cache() {
  if [[ -z "${PLATFORM_CACHE[initialized]:-}" ]]; then
    PLATFORM_CACHE[os]="$(uname -s)"
    PLATFORM_CACHE[arch]="$(uname -m)"
    PLATFORM_CACHE[ostype]="${OSTYPE:-}"
    PLATFORM_CACHE[initialized]=1
  fi
}

get_os() {
  init_platform_cache
  echo "${PLATFORM_CACHE[os]}"
}

get_arch() {
  init_platform_cache
  echo "${PLATFORM_CACHE[arch]}"
}

is_macos() {
  init_platform_cache
  [[ "${PLATFORM_CACHE[os]}" == "Darwin" ]]
}

is_linux() {
  init_platform_cache
  [[ "${PLATFORM_CACHE[os]}" == "Linux" ]]
}

is_apple_silicon() {
  init_platform_cache
  [[ "${PLATFORM_CACHE[arch]}" == "arm64" ]]
}

export -f init_platform_cache
export -f get_os
export -f get_arch
export -f is_macos
export -f is_linux
export -f is_apple_silicon

