#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SCRIPTS_PATH="${PROJECT_ROOT}/src"

system="#($SCRIPTS_PATH/system-widget.sh)"
netspeed="#($SCRIPTS_PATH/network-widget.sh)"
git="#($SCRIPTS_PATH/git-widget.sh #{pane_current_path})"
context="#($SCRIPTS_PATH/context-widget.sh)"

WIDGETS_ORDER="$(tmux show-option -gv @yoru_widgets_order 2>/dev/null)"
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
  case "$widget" in
    system)
      STATUS_RIGHT="${STATUS_RIGHT}#($SCRIPTS_PATH/system-widget.sh)"
      ;;
    git)
      STATUS_RIGHT="${STATUS_RIGHT}#($SCRIPTS_PATH/git-widget.sh #{pane_current_path})"
      ;;
    netspeed)
      STATUS_RIGHT="${STATUS_RIGHT}#($SCRIPTS_PATH/network-widget.sh)"
      ;;
    context)
      STATUS_RIGHT="${STATUS_RIGHT}#($SCRIPTS_PATH/context-widget.sh)"
      ;;
  esac
done

echo "$STATUS_RIGHT"

