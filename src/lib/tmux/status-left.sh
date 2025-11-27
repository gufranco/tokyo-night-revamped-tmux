#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."

source "${LIB_DIR}/ui/themes.sh"
source "${LIB_DIR}/ui/color-config.sh"
source "${LIB_DIR}/tmux/tmux-ops.sh"
source "${LIB_DIR}/widget/widget-config.sh"

SHOW_SESSION=$(is_widget_feature_enabled "@tokyo-night-tmux_status_left_show_session" "1")
SHOW_WINDOWS=$(is_widget_feature_enabled "@tokyo-night-tmux_status_left_show_windows" "0")
SHOW_PANES=$(is_widget_feature_enabled "@tokyo-night-tmux_status_left_show_panes" "0")
SHOW_SYNC=$(is_widget_feature_enabled "@tokyo-night-tmux_status_left_show_sync" "1")
SHOW_ZOOM=$(is_widget_feature_enabled "@tokyo-night-tmux_status_left_show_zoom" "1")
SHOW_MOUSE=$(is_widget_feature_enabled "@tokyo-night-tmux_status_left_show_mouse" "0")
SHOW_HOSTNAME=$(is_widget_feature_enabled "@tokyo-night-tmux_status_left_show_hostname" "0")

USERNAME="${USER:-$(whoami)}"
GREEN=$(get_custom_color "status_left_green" "${THEME[green]}")
CYAN=$(get_custom_color "status_left_cyan" "${THEME[cyan]}")
YELLOW=$(get_custom_color "status_left_yellow" "${THEME[yellow]}")
RESET_FMT="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

main() {
  local output=""
  local prefix_active=0
  local session_name=""
  local window_count=0
  local pane_count=0
  local sync_mode=0
  local zoom_mode=0
  local mouse_mode=0
  local hostname=""
  local tmux_data
  local combined_query=""

  if [[ $SHOW_SESSION -eq 1 ]] || [[ $SHOW_ZOOM -eq 1 ]] || [[ $SHOW_WINDOWS -eq 1 ]] || [[ $SHOW_PANES -eq 1 ]] || [[ $SHOW_SYNC -eq 1 ]] || [[ $SHOW_MOUSE -eq 1 ]]; then
    combined_query="#{?client_prefix,1,0}"
    [[ $SHOW_SESSION -eq 1 ]] && combined_query="${combined_query}::#{S}"
    [[ $SHOW_ZOOM -eq 1 ]] && combined_query="${combined_query}::#{?window_zoomed_flag,1,0}"
    [[ $SHOW_SYNC -eq 1 ]] && combined_query="${combined_query}::#{?#{==:#{pane_synchronized},1},1,0}"
    [[ $SHOW_MOUSE -eq 1 ]] && combined_query="${combined_query}::#{?mouse_flag,1,0}"
    [[ $SHOW_WINDOWS -eq 1 ]] && combined_query="${combined_query}::#{window_count}"
    [[ $SHOW_PANES -eq 1 ]] && combined_query="${combined_query}::#{pane_count}"

    tmux_data=$(tmux display-message -p "$combined_query" 2>/dev/null || echo "")

    if [[ -n "$tmux_data" ]]; then
      IFS='::' read -r prefix_active session_name zoom_mode sync_mode mouse_mode window_count pane_count <<< "$tmux_data"
      prefix_active="${prefix_active:-0}"
      session_name="${session_name:-}"
      zoom_mode="${zoom_mode:-0}"
      sync_mode="${sync_mode:-0}"
      mouse_mode="${mouse_mode:-0}"
      window_count="${window_count:-0}"
      pane_count="${pane_count:-0}"
    fi
  else
    prefix_active=$(tmux display-message -p '#{?client_prefix,1,0}' 2>/dev/null || echo "0")
  fi

  if [[ $SHOW_HOSTNAME -eq 1 ]]; then
    if [[ -n "${SSH_CLIENT:-}" ]] || [[ -n "${SSH_TTY:-}" ]]; then
      hostname="${HOSTNAME:-$(hostname -s 2>/dev/null || hostname 2>/dev/null | cut -d. -f1 || echo "")}"
      hostname="${hostname//[^a-zA-Z0-9._-]/}"
    fi
  fi

  local icon_color
  local username_color
  local separator_color

  if [[ $prefix_active -eq 1 ]]; then
    icon_color="${GREEN}"
    username_color="${GREEN}"
    separator_color="${GREEN}"
  else
    icon_color="${CYAN}"
    username_color="${CYAN}"
    separator_color="${CYAN}"
  fi

  output="#[fg=${icon_color}]󰀄#[fg=${username_color}] ${USERNAME}"

  if [[ -n "$session_name" ]] && [[ "$session_name" != "$USERNAME" ]]; then
    output="${output}#[fg=${CYAN}] @ ${session_name}"
  fi

  if [[ $SHOW_WINDOWS -eq 1 ]] || [[ $SHOW_PANES -eq 1 ]]; then
    local counts=""
    if [[ $SHOW_WINDOWS -eq 1 ]]; then
      counts="${window_count}w"
    fi
    if [[ $SHOW_PANES -eq 1 ]]; then
      [[ -n "$counts" ]] && counts="${counts}:"
      counts="${counts}${pane_count}p"
    fi
    [[ -n "$counts" ]] && output="${output} #[fg=${CYAN}][${counts}]"
  fi

  local indicators=""

  [[ $sync_mode -eq 1 ]] && indicators="${indicators}SYNC"
  if [[ $zoom_mode -eq 1 ]]; then
    [[ -n "$indicators" ]] && indicators="${indicators} "
    indicators="${indicators}ZOOM"
  fi
  if [[ $mouse_mode -eq 1 ]]; then
    [[ -n "$indicators" ]] && indicators="${indicators} "
    indicators="${indicators}MOUSE"
  fi
  if [[ -n "$hostname" ]]; then
    [[ -n "$indicators" ]] && indicators="${indicators} "
    indicators="${indicators}@${hostname}"
  fi

  [[ -n "$indicators" ]] && output="${output} #[fg=${YELLOW}][${indicators}]"

  output="${output} #[fg=${separator_color}]░${RESET_FMT} "
  echo "$output"
}

main

