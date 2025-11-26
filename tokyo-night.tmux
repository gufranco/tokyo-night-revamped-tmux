
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$CURRENT_DIR/src"

source "$SCRIPTS_PATH/lib/themes.sh"

tmux set -g status-left-length 40
tmux set -g status-right-length 200

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

tmux set -g mode-style "fg=${THEME[bgreen]},bg=${THEME[bblack]}"
tmux set -g message-style "bg=${THEME[bblack]},fg=${THEME[blue]},bold"
tmux set -g message-command-style "bg=${THEME[bblack]},fg=${THEME[white]},bold"
tmux set -g pane-border-style "fg=${THEME[bblack]}"
tmux set -g pane-active-border-style "fg=${THEME[blue]}"
tmux set -g pane-border-status off
tmux set -g status-style bg="${THEME[background]}"
tmux set -g popup-border-style "fg=${THEME[blue]}"
TMUX_VARS="$(tmux show -g)"

window_number="#I"
custom_pane="#P"
zoom_number="#P"

system="#($SCRIPTS_PATH/system-widget.sh)"
netspeed="#($SCRIPTS_PATH/network-widget.sh)"
git="#($SCRIPTS_PATH/git-widget.sh #{pane_current_path})"
context="#($SCRIPTS_PATH/context-widget.sh)"

git_status="$git"
date_and_time="$context"

GREEN="${THEME[green]}"
CYAN="${THEME[cyan]}"
RESET_FMT="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

tmux set -g status-left "#{?client_prefix,#[fg=${GREEN}]#[bold]󰀄 gufranco #[fg=${GREEN}]░,#[fg=${CYAN}]󰀄 gufranco #[fg=${CYAN}]░}${RESET_FMT} "

tmux set -g window-status-current-format "${RESET_FMT}#[fg=${THEME[cyan]},bold]$window_number #W #[fg=${THEME[cyan]}]░ "

tmux set -g window-status-format "${RESET_FMT}#[fg=${THEME[foreground]},dim]$window_number #W #[fg=${THEME[cyan]},dim]░ "

tmux set -g window-status-separator ""
WIDGETS_ORDER="$(tmux show-option -gv @tokyo-night-tmux_widgets_order 2>/dev/null)"

if [[ -z "$WIDGETS_ORDER" ]]; then
  WIDGETS_ORDER="system,git,netspeed,context"
fi

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
