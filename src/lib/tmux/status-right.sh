#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="${SCRIPT_DIR}/../.."

system="#($SCRIPTS_PATH/system-widget.sh)"
netspeed="#($SCRIPTS_PATH/network-widget.sh)"
git="#($SCRIPTS_PATH/git-widget.sh #{pane_current_path})"
context="#($SCRIPTS_PATH/context-widget.sh)"

WIDGETS_ORDER="$(tmux show-option -gv @tokyo-night-tmux_widgets_order 2>/dev/null)"
[[ -z "$WIDGETS_ORDER" ]] && WIDGETS_ORDER="system,git,netspeed,context"

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
  [[ -n "${WIDGET_MAP[$widget]}" ]] && STATUS_RIGHT="${STATUS_RIGHT}${WIDGET_MAP[$widget]}"
done

echo "$STATUS_RIGHT"

