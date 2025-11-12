#!/usr/bin/env bash
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# title      Tokyo Night                                              +
# version    1.0.0                                                    +
# repository https://github.com/logico-dev/tokyo-night-tmux           +
# author     Lógico                                                   +
# email      hi@logico.com.ar                                         +
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$CURRENT_DIR/src"

source $SCRIPTS_PATH/themes.sh

tmux set -g status-left-length 80
tmux set -g status-right-length 150

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"
# Highlight colors
tmux set -g mode-style "fg=${THEME[bgreen]},bg=${THEME[bblack]}"

# Message styles with improved contrast for better readability
tmux set -g message-style "bg=${THEME[bblack]},fg=${THEME[blue]},bold"
tmux set -g message-command-style "bg=${THEME[bblack]},fg=${THEME[white]},bold"

tmux set -g pane-border-style "fg=${THEME[bblack]}"
tmux set -g pane-active-border-style "fg=${THEME[blue]}"
tmux set -g pane-border-status off

tmux set -g status-style bg="${THEME[background]}"
tmux set -g popup-border-style "fg=${THEME[blue]}"

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

# Widget definitions
netspeed="#($SCRIPTS_PATH/netspeed.sh)"
music="#($SCRIPTS_PATH/music-tmux-statusbar.sh)"
git="#($SCRIPTS_PATH/git-status.sh #{pane_current_path})"
wbg="#($SCRIPTS_PATH/wb-git-status.sh #{pane_current_path} &)"
window_number="#($SCRIPTS_PATH/custom-number.sh #I $window_id_style)"
custom_pane="#($SCRIPTS_PATH/custom-number.sh #P $pane_id_style)"
zoom_number="#($SCRIPTS_PATH/custom-number.sh #P $zoom_id_style)"
datetime="#($SCRIPTS_PATH/datetime-widget.sh)"
path="#($SCRIPTS_PATH/path-widget.sh #{pane_current_path})"
battery="#($SCRIPTS_PATH/battery-widget.sh)"

# Legacy variable names for compatibility
cmus_status="$music"
git_status="$git"
wb_git_status="$wbg"
date_and_time="$datetime"
current_path="$path"
battery_status="$battery"

#+--- Bars LEFT ---+
# Session name
tmux set -g status-left "#[fg=${THEME[bblack]},bg=${THEME[blue]},bold] #{?client_prefix,󰠠 ,#[dim]󰤂 }#[bold,nodim]#S "

#+--- Windows ---+
# Focus
tmux set -g window-status-current-format "$RESET#[fg=${THEME[green]},bg=${THEME[bblack]}] #{?#{==:#{pane_current_command},ssh},󰣀 ,  }#[fg=${THEME[foreground]},bold,nodim]$window_number#W#[nobold]#{?window_zoomed_flag, $zoom_number, $custom_pane}#{?window_last_flag, , }"
# Unfocused
tmux set -g window-status-format "$RESET#[fg=${THEME[foreground]}] #{?#{==:#{pane_current_command},ssh},󰣀 ,  }${RESET}$window_number#W#[nobold,dim]#{?window_zoomed_flag, $zoom_number, $custom_pane}#[fg=${THEME[yellow]}]#{?window_last_flag,󰁯  , }"

#+--- Bars RIGHT ---+
# Widget order configuration
WIDGETS_ORDER="$(tmux show-option -gv @tokyo-night-tmux_widgets_order 2>/dev/null)"

# Default order if not specified
if [[ -z "$WIDGETS_ORDER" ]]; then
  WIDGETS_ORDER="battery,path,music,netspeed,git,wbg,datetime"
fi

# Build status-right based on widget order
declare -A WIDGET_MAP=(
  ["battery"]="$battery"
  ["path"]="$path"
  ["music"]="$music"
  ["netspeed"]="$netspeed"
  ["git"]="$git"
  ["wbg"]="$wbg"
  ["datetime"]="$datetime"
)

STATUS_RIGHT=""
IFS=',' read -ra WIDGETS <<< "$WIDGETS_ORDER"
for widget in "${WIDGETS[@]}"; do
  # Trim whitespace
  widget=$(echo "$widget" | xargs)
  
  if [[ -n "${WIDGET_MAP[$widget]}" ]]; then
    STATUS_RIGHT="${STATUS_RIGHT}${WIDGET_MAP[$widget]}"
  fi
done

tmux set -g status-right "$STATUS_RIGHT"
tmux set -g window-status-separator ""
