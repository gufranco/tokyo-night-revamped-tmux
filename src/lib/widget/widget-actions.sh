#!/usr/bin/env bash

execute_widget_action() {
  local widget_name=$1
  local action=$2
  
  case "$widget_name" in
    system)
      case "$action" in
        htop) command -v htop >/dev/null 2>&1 && tmux new-window -d "htop" ;;
        top) tmux new-window -d "top" ;;
        *) return 1 ;;
      esac
      ;;
    git)
      case "$action" in
        status) tmux send-keys "git status" Enter ;;
        log) tmux send-keys "git log --oneline -10" Enter ;;
        *) return 1 ;;
      esac
      ;;
    network)
      case "$action" in
        iftop) command -v iftop >/dev/null 2>&1 && tmux new-window -d "sudo iftop" ;;
        nethogs) command -v nethogs >/dev/null 2>&1 && tmux new-window -d "sudo nethogs" ;;
        *) return 1 ;;
      esac
      ;;
    docker)
      case "$action" in
        ps) tmux send-keys "docker ps" Enter ;;
        stats) tmux send-keys "docker stats" Enter ;;
        *) return 1 ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac
  
  return 0
}

get_widget_actions() {
  local widget_name=$1
  
  case "$widget_name" in
    system)
      echo "htop,top"
      ;;
    git)
      echo "status,log"
      ;;
    network)
      echo "iftop,nethogs"
      ;;
    docker)
      echo "ps,stats"
      ;;
    *)
      echo ""
      ;;
  esac
}

export -f execute_widget_action
export -f get_widget_actions

