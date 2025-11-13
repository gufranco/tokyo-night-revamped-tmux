#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${SCRIPT_DIR}/themes.sh"

MINIMAL_SESSION=$(tmux show-option -gv @tokyo-night-tmux_minimal_session 2>/dev/null)
CURRENT_SESSION=$(tmux display-message -p '#S')

[[ -n "$MINIMAL_SESSION" ]] && [[ "$MINIMAL_SESSION" == "$CURRENT_SESSION" ]] && exit 0

SHOW_GIT=$(tmux show-option -gv @tokyo-night-tmux_show_git 2>/dev/null)
[[ "$SHOW_GIT" == "0" ]] && exit 0

cd "$1" || exit 0

git rev-parse --git-dir &>/dev/null || exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

CHECK_UNTRACKED=$(tmux show-option -gv @tokyo-night-tmux_git_untracked 2>/dev/null)
CHECK_UNTRACKED="${CHECK_UNTRACKED:-1}"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [[ ${#BRANCH} -gt 25 ]]; then
  BRANCH="${BRANCH:0:25}…"
fi

STATUS=$(git status --porcelain 2>/dev/null | grep -cE "^(M| M)")

CHANGED=0
INSERTIONS=0
DELETIONS=0
UNTRACKED=0

if [[ $STATUS -gt 0 ]]; then
  DIFF_OUTPUT=$(git diff --numstat 2>/dev/null)
  
  if [[ -n "$DIFF_OUTPUT" ]]; then
    while IFS=$'\t' read -r added removed file; do
      (( CHANGED++ ))
      [[ "$added" =~ ^[0-9]+$ ]] && (( INSERTIONS += added ))
      [[ "$removed" =~ ^[0-9]+$ ]] && (( DELETIONS += removed ))
    done <<< "$DIFF_OUTPUT"
  fi
  
  SYNC_MODE="local_changes"
else
  NEED_PUSH=$(git log @{push}.. 2>/dev/null | wc -l | tr -d ' ')
  
  if [[ "$NEED_PUSH" =~ ^[0-9]+$ ]] && (( NEED_PUSH > 0 )); then
    SYNC_MODE="need_push"
  else
    SYNC_MODE="clean"
  fi
fi

if [[ $CHECK_UNTRACKED -eq 1 ]]; then
  UNTRACKED=$(git ls-files --other --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
fi

case "$SYNC_MODE" in
local_changes)
    REMOTE_ICON="󱓎"
    REMOTE_COLOR="${THEME[bred]}"
  ;;
need_push)
    REMOTE_ICON="󰛃"
    REMOTE_COLOR="${THEME[red]}"
  ;;
remote_ahead)
    REMOTE_ICON="󰛀"
    REMOTE_COLOR="${THEME[magenta]}"
  ;;
*)
    REMOTE_ICON=""
    REMOTE_COLOR="${THEME[green]}"
  ;;
esac

OUTPUT="$RESET#[bg=${THEME[background]},fg=${REMOTE_COLOR},bold]▒ ${REMOTE_ICON} ${RESET}${BRANCH}"

if [[ $CHANGED -gt 0 ]]; then
  OUTPUT="${OUTPUT} ${RESET}#[fg=${THEME[yellow]},bg=${THEME[background]}]󰄴 ${CHANGED}"
fi

if [[ $INSERTIONS -gt 0 ]]; then
  OUTPUT="${OUTPUT} ${RESET}#[fg=${THEME[green]},bg=${THEME[background]}]󰐕 ${INSERTIONS}"
fi

if [[ $DELETIONS -gt 0 ]]; then
  OUTPUT="${OUTPUT} ${RESET}#[fg=${THEME[red]},bg=${THEME[background]}]󰍵 ${DELETIONS}"
fi

if [[ $UNTRACKED -gt 0 ]]; then
  OUTPUT="${OUTPUT} ${RESET}#[fg=${THEME[cyan]},bg=${THEME[background]}]󰋗 ${UNTRACKED}"
fi

echo "${OUTPUT} "
