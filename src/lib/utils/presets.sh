#!/usr/bin/env bash

apply_preset() {
  local preset_name=$1

  case "$preset_name" in
    minimal)
      tmux set-option -g @yoru_show_system 0
      tmux set-option -g @yoru_show_git 1
      tmux set-option -g @yoru_show_netspeed 0
      tmux set-option -g @yoru_show_context 1
      tmux set-option -g @yoru_show_process 0
      tmux set-option -g @yoru_show_docker 0
      tmux set-option -g @yoru_show_health 0
      tmux set-option -g @yoru_widgets_order "git,context"
      ;;
    developer)
      tmux set-option -g @yoru_show_system 1
      tmux set-option -g @yoru_show_git 1
      tmux set-option -g @yoru_show_netspeed 0
      tmux set-option -g @yoru_show_context 1
      tmux set-option -g @yoru_show_process 0
      tmux set-option -g @yoru_show_docker 0
      tmux set-option -g @yoru_show_health 0
      tmux set-option -g @yoru_widgets_order "system,git,context"
      tmux set-option -g @yoru_system_cpu 1
      tmux set-option -g @yoru_system_memory 1
      tmux set-option -g @yoru_system_disk 1
      tmux set-option -g @yoru_git_web 1
      ;;
    monitoring)
      tmux set-option -g @yoru_show_system 1
      tmux set-option -g @yoru_show_git 0
      tmux set-option -g @yoru_show_netspeed 1
      tmux set-option -g @yoru_show_context 1
      tmux set-option -g @yoru_show_process 1
      tmux set-option -g @yoru_show_docker 1
      tmux set-option -g @yoru_show_health 1
      tmux set-option -g @yoru_widgets_order "system,process,docker,health,netspeed,context"
      tmux set-option -g @yoru_system_cpu 1
      tmux set-option -g @yoru_system_memory 1
      tmux set-option -g @yoru_system_disk 1
      ;;
    full)
      tmux set-option -g @yoru_show_system 1
      tmux set-option -g @yoru_show_git 1
      tmux set-option -g @yoru_show_netspeed 1
      tmux set-option -g @yoru_show_context 1
      tmux set-option -g @yoru_show_process 1
      tmux set-option -g @yoru_show_docker 1
      tmux set-option -g @yoru_show_health 1
      tmux set-option -g @yoru_widgets_order "system,process,docker,health,git,netspeed,context"
      ;;
    *)
      return 1
      ;;
  esac

  return 0
}

export -f apply_preset

