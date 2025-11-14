#!/usr/bin/env bash

if [[ "$(uname)" == "Darwin" ]]; then
  HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null)"
  
  if [[ -n "$HOMEBREW_PREFIX" ]]; then
    if [ -d "$HOMEBREW_PREFIX/opt/coreutils" ]; then
      export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
    fi
    if [ -d "$HOMEBREW_PREFIX/opt/gawk" ]; then
      export PATH="$HOMEBREW_PREFIX/opt/gawk/libexec/gnubin:$PATH"
    fi
    if [ -d "$HOMEBREW_PREFIX/opt/gsed" ]; then
      export PATH="$HOMEBREW_PREFIX/opt/gsed/libexec/gnubin:$PATH"
    fi
  fi
fi


get_file_mtime() {
  local file="${1}"
  
  if [[ ! -f "${file}" ]]; then
    echo "0"
    return
  fi
  
  if [[ "$(uname)" == "Darwin" ]]; then
    stat -f "%m" "${file}" 2>/dev/null || echo "0"
  else
    stat -c "%Y" "${file}" 2>/dev/null || echo "0"
  fi
}

get_current_timestamp() {
  date +%s
}

get_time_diff() {
  local start="${1}"
  local end="${2:-$(get_current_timestamp)}"
  
  echo "$((end - start))"
}

export -f get_file_mtime
export -f get_current_timestamp
export -f get_time_diff
