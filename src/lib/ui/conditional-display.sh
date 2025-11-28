#!/usr/bin/env bash

should_display_widget() {
  local widget_name=$1
  local condition
  
  case "$widget_name" in
    system)
      condition=$(tmux show-option -gv @yoru_revamped_show_system 2>/dev/null)
      ;;
    git)
      condition=$(tmux show-option -gv @yoru_revamped_show_git 2>/dev/null)
      ;;
    netspeed)
      condition=$(tmux show-option -gv @yoru_revamped_show_netspeed 2>/dev/null)
      ;;
    context)
      condition=$(tmux show-option -gv @yoru_revamped_show_context 2>/dev/null)
      ;;
    process)
      condition=$(tmux show-option -gv @yoru_revamped_show_process 2>/dev/null)
      ;;
    docker)
      condition=$(tmux show-option -gv @yoru_revamped_show_docker 2>/dev/null)
      ;;
    health)
      condition=$(tmux show-option -gv @yoru_revamped_show_health 2>/dev/null)
      ;;
    *)
      return 0
      ;;
  esac
  
  [[ "$condition" == "1" ]]
}

should_display_time_based() {
  local start_hour=${1:-0}
  local end_hour=${2:-23}
  local current_hour
  
  current_hour=$(date +%H 2>/dev/null)
  current_hour="${current_hour#0}"
  
  if (( start_hour <= end_hour )); then
    (( current_hour >= start_hour && current_hour <= end_hour ))
  else
    (( current_hour >= start_hour || current_hour <= end_hour ))
  fi
}

export -f should_display_widget
export -f should_display_time_based

