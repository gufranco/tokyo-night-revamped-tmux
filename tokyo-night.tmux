#!/usr/bin/env bash
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# title      Tokyo Night Revamped                                     +
# version    2.0.0                                                    +
# repository https://github.com/gufranco/tokyo-night-revamped-tmux    +
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$CURRENT_DIR/src"

source "$SCRIPTS_PATH/lib/themes.sh"

# ==============================================================================
# Status Bar Configuration
# ==============================================================================
tmux set -g status-left-length 80
tmux set -g status-right-length 200

# ==============================================================================
# Color Scheme
# ==============================================================================
RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# Highlight colors
tmux set -g mode-style "fg=${THEME[bgreen]},bg=${THEME[bblack]}"

# Message styles with improved contrast for better readability
tmux set -g message-style "bg=${THEME[bblack]},fg=${THEME[blue]},bold"
tmux set -g message-command-style "bg=${THEME[bblack]},fg=${THEME[white]},bold"

# Pane borders
tmux set -g pane-border-style "fg=${THEME[bblack]}"
tmux set -g pane-active-border-style "fg=${THEME[blue]}"
tmux set -g pane-border-status off

# Status bar background
tmux set -g status-style bg="${THEME[background]}"
tmux set -g popup-border-style "fg=${THEME[blue]}"

# ==============================================================================
# Number Styles Configuration
# ==============================================================================
TMUX_VARS="$(tmux show -g)"

default_window_id_style="digital"
default_pane_id_style="hsquare"
default_zoom_id_style="dsquare"

window_id_style="$(echo "$TMUX_VARS" | grep '@tokyo-night-tmux_window_id_style' | cut -d" " -f2)"
pane_id_style="$(echo "$TMUX_VARS" | grep '@tokyo-night-tmux_pane_id_style' | cut -d" " -f2)"
zoom_id_style="$(echo "$TMUX_VARS" | grep '@tokyo-night-tmux_zoom_id_style' | cut -d" " -f2)"

window_id_style="${window_id_style:-$default_window_id_style}"
pane_id_style="${pane_id_style:-$default_pane_id_style}"
zoom_id_style="${zoom_id_style:-$default_zoom_id_style}"

window_number="#($SCRIPTS_PATH/number-widget.sh #I $window_id_style)"
custom_pane="#($SCRIPTS_PATH/number-widget.sh #P $pane_id_style)"
zoom_number="#($SCRIPTS_PATH/number-widget.sh #P $zoom_id_style)"

# ==============================================================================
# Widget Definitions (organized by context)
# ==============================================================================

# System Resources
system="#($SCRIPTS_PATH/system-widget.sh)"

# Network & Connectivity
netspeed="#($SCRIPTS_PATH/network-widget.sh)"

# Development & Git
git="#($SCRIPTS_PATH/git-widget.sh #{pane_current_path})"

# Environment & Context
context="#($SCRIPTS_PATH/context-widget.sh)"

# Legacy variable names for compatibility
git_status="$git"
date_and_time="$context"

# ==============================================================================
# Status Left (Session Name)
# ==============================================================================
tmux set -g status-left "#[fg=${THEME[bblack]},bg=${THEME[blue]},bold] #{?client_prefix,󰠠 ,#[dim]󰤂 }#[bold,nodim]#S "

# ==============================================================================
# Window Status Format
# ==============================================================================
# Active window
tmux set -g window-status-current-format "$RESET#[fg=${THEME[cyan]},bg=${THEME[bblack]}] #{?#{==:#{pane_current_command},ssh},󰣀 ,  }#[fg=${THEME[foreground]},bold,nodim]$window_number#W#[nobold]#{?window_zoomed_flag, $zoom_number, $custom_pane}#{?window_last_flag, , }"

# Inactive windows
tmux set -g window-status-format "$RESET#[fg=${THEME[foreground]}] #{?#{==:#{pane_current_command},ssh},󰣀 ,  }${RESET}$window_number#W#[nobold,dim]#{?window_zoomed_flag, $zoom_number, $custom_pane}#[fg=${THEME[cyan]}]#{?window_last_flag,󰁯  , }"

tmux set -g window-status-separator ""

# ==============================================================================
# Status Right (Widget Order Configuration)
# ==============================================================================
WIDGETS_ORDER="$(tmux show-option -gv @tokyo-night-tmux_widgets_order 2>/dev/null)"

if [[ -z "$WIDGETS_ORDER" ]]; then
  WIDGETS_ORDER="system,git,netspeed,context"
fi

# Build widget mapping
declare -A WIDGET_MAP=(
  ["system"]="$system"
  ["git"]="$git"
  ["netspeed"]="$netspeed"
  ["context"]="$context"
)

STATUS_RIGHT=""
IFS=',' read -ra WIDGETS <<< "$WIDGETS_ORDER"
for widget in "${WIDGETS[@]}"; do
  widget="${widget// /}"
  
  if [[ -n "${WIDGET_MAP[$widget]}" ]]; then
    STATUS_RIGHT="${STATUS_RIGHT}${WIDGET_MAP[$widget]}"
  fi
done

tmux set -g status-right "$STATUS_RIGHT"
