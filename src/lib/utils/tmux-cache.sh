#!/usr/bin/env bash

declare -gA TMUX_OPTION_CACHE
declare -g TMUX_CACHE_INITIALIZED=0

init_tmux_cache() {
  [[ $TMUX_CACHE_INITIALIZED -eq 1 ]] && return

  local refresh_rate
  refresh_rate=$(tmux show-option -gv @tokyo-night-tmux_refresh_rate 2>/dev/null)
  TMUX_OPTION_CACHE[refresh_rate]="${refresh_rate:-5}"

  TMUX_CACHE_INITIALIZED=1
}

get_cached_refresh_rate() {
  init_tmux_cache
  echo "${TMUX_OPTION_CACHE[refresh_rate]:-5}"
}

export -f init_tmux_cache
export -f get_cached_refresh_rate

