#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."
SCRIPTS_PATH="${SCRIPT_DIR}/../.."

source "${LIB_DIR}/ui/themes.sh"

RESET_FMT="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

tmux set -g status-left-length 0
tmux set -g status-right-length 0

tmux set -g mode-style "fg=${THEME[bgreen]},bg=${THEME[bblack]}"
tmux set -g message-style "bg=${THEME[bblack]},fg=${THEME[blue]},bold"
tmux set -g message-command-style "bg=${THEME[bblack]},fg=${THEME[white]},bold"
tmux set -g pane-border-style "fg=${THEME[bblack]}"
tmux set -g pane-active-border-style "fg=${THEME[blue]}"
tmux set -g pane-border-status off
tmux set -g status-style bg="${THEME[background]}"
tmux set -g popup-border-style "fg=${THEME[blue]}"

window_number="#I"
tmux set -g window-status-current-format "${RESET_FMT}#[fg=${THEME[cyan]},bold]$window_number #W #[fg=${THEME[cyan]}]░ "
tmux set -g window-status-format "${RESET_FMT}#[fg=${THEME[foreground]},dim]$window_number #W #[fg=${THEME[cyan]},dim]░ "
tmux set -g window-status-separator ""

status_left_script="#($SCRIPTS_PATH/lib/tmux/status-left.sh)"
tmux set -g status-left "$status_left_script"

status_right_script="#($SCRIPTS_PATH/lib/tmux/status-right.sh)"
tmux set -g status-right "$status_right_script"

