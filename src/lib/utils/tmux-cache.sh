#!/usr/bin/env bash

declare -gA TMUX_OPTION_CACHE
declare -g TMUX_CACHE_INITIALIZED=0
declare -g TMUX_CACHE_TIMESTAMP=0
TMUX_CACHE_TTL="${TMUX_CACHE_TTL:-30}"

init_tmux_cache() {
  local current_time
  current_time=$(date +%s 2>/dev/null || echo "0")
  
  if [[ $TMUX_CACHE_INITIALIZED -eq 1 ]] && [[ $((current_time - TMUX_CACHE_TIMESTAMP)) -lt $TMUX_CACHE_TTL ]]; then
    return
  fi

  TMUX_OPTION_CACHE[refresh_rate]="$(tmux show-option -gv @tokyo-night-tmux_refresh_rate 2>/dev/null || echo "5")"
  TMUX_OPTION_CACHE[widgets_order]="$(tmux show-option -gv @tokyo-night-tmux_widgets_order 2>/dev/null || echo "")"
  TMUX_OPTION_CACHE[show_system]="$(tmux show-option -gv @tokyo-night-tmux_show_system 2>/dev/null || echo "1")"
  TMUX_OPTION_CACHE[show_git]="$(tmux show-option -gv @tokyo-night-tmux_show_git 2>/dev/null || echo "1")"
  TMUX_OPTION_CACHE[show_netspeed]="$(tmux show-option -gv @tokyo-night-tmux_show_netspeed 2>/dev/null || echo "1")"
  TMUX_OPTION_CACHE[show_context]="$(tmux show-option -gv @tokyo-night-tmux_show_context 2>/dev/null || echo "1")"
  TMUX_OPTION_CACHE[enable_logging]="$(tmux show-option -gv @tokyo-night-tmux_enable_logging 2>/dev/null || echo "0")"
  TMUX_OPTION_CACHE[enable_profiling]="$(tmux show-option -gv @tokyo-night-tmux_enable_profiling 2>/dev/null || echo "0")"
  TMUX_OPTION_CACHE[minimal_session]="$(tmux show-option -gv @tokyo-night-tmux_minimal_session 2>/dev/null || echo "")"

  TMUX_CACHE_TIMESTAMP=$current_time
  TMUX_CACHE_INITIALIZED=1
}

get_cached_refresh_rate() {
  init_tmux_cache
  echo "${TMUX_OPTION_CACHE[refresh_rate]:-5}"
}

get_cached_tmux_option() {
  local option="${1}"
  local default="${2:-}"
  
  init_tmux_cache
  
  local cache_key="${option#@}"
  cache_key="${cache_key//-/_}"
  cache_key="${cache_key//tokyo_night_tmux_/}"
  
  if [[ -n "${TMUX_OPTION_CACHE[$cache_key]:-}" ]]; then
    echo "${TMUX_OPTION_CACHE[$cache_key]}"
  else
    local value
    value=$(tmux show-option -gv "$option" 2>/dev/null)
    [[ -z "$value" ]] && echo "$default" || echo "$value"
  fi
}

invalidate_tmux_cache() {
  TMUX_CACHE_INITIALIZED=0
  TMUX_CACHE_TIMESTAMP=0
  TMUX_OPTION_CACHE=()
}

export -f init_tmux_cache
export -f get_cached_refresh_rate
export -f get_cached_tmux_option
export -f invalidate_tmux_cache

