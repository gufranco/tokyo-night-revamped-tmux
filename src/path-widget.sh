#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/widget-base.sh"
source "${SCRIPT_DIR}/themes.sh"

is_widget_enabled "@tokyo-night-tmux_show_path" || exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

PATH_FORMAT=$(tmux show-option -gv @tokyo-night-tmux_path_format 2>/dev/null)
PATH_FORMAT="${PATH_FORMAT:-$DEFAULT_PATH_FORMAT}"

CURRENT_PATH="${1}"

format_path() {
  local path="${1}"
  local format="${2}"
  
  if [[ "$format" == "full" ]]; then
    echo "$path"
  else
    echo "${path/#$HOME/~}"
  fi
}

main() {
  local display_path
  
  display_path=$(format_path "$CURRENT_PATH" "$PATH_FORMAT")
  
  echo "#[fg=${THEME[cyan]},bg=default]░ ${ICON_PATH}${RESET} ${display_path} "
}

main
