#!/usr/bin/env bash
# Verify if the current session is the minimal session
MINIMAL_SESSION_NAME=$(tmux show-option -gv @tokyo-night-tmux_minimal_session 2>/dev/null)
TMUX_SESSION_NAME=$(tmux display-message -p '#S')

if [ "$MINIMAL_SESSION_NAME" = "$TMUX_SESSION_NAME" ]; then
  exit 0
fi

SHOW_GIT=$(tmux show-option -gv @tokyo-night-tmux_show_git)
if [ "$SHOW_GIT" == "0" ]; then
  exit 0
fi

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/../lib/coreutils-compat.sh"
source "$CURRENT_DIR/../lib/git.sh"
source "$CURRENT_DIR/themes.sh"

cd "$1" || exit 1

# Exit if not a git repository
if ! is_git_repository; then
  exit 0
fi

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# Get branch name
BRANCH=$(get_git_branch_truncated 25)

# Get sync status
SYNC_MODE=$(get_repository_sync_status)

# Initialize counters
CHANGED_COUNT=0
INSERTIONS_COUNT=0
DELETIONS_COUNT=0
UNTRACKED_COUNT=0

# Get detailed stats if there are local changes
if [[ "$SYNC_MODE" == "local_changes" ]]; then
  read -r CHANGED_COUNT INSERTIONS_COUNT DELETIONS_COUNT < <(get_git_diff_stats)
fi

# Check untracked files if enabled
CHECK_UNTRACKED=$(tmux show-option -gv @tokyo-night-tmux_git_check_untracked 2>/dev/null)
CHECK_UNTRACKED="${CHECK_UNTRACKED:-1}"

if [[ $CHECK_UNTRACKED -eq 1 ]]; then
  UNTRACKED_COUNT=$(get_git_untracked_count)
fi

# Format output strings
STATUS_CHANGED=""
STATUS_INSERTIONS=""
STATUS_DELETIONS=""
STATUS_UNTRACKED=""

if [[ $CHANGED_COUNT -gt 0 ]]; then
  STATUS_CHANGED="${RESET}#[fg=${THEME[yellow]},bg=${THEME[background]},bold] ${CHANGED_COUNT} "
fi

if [[ $INSERTIONS_COUNT -gt 0 ]]; then
  STATUS_INSERTIONS="${RESET}#[fg=${THEME[green]},bg=${THEME[background]},bold] ${INSERTIONS_COUNT} "
fi

if [[ $DELETIONS_COUNT -gt 0 ]]; then
  STATUS_DELETIONS="${RESET}#[fg=${THEME[red]},bg=${THEME[background]},bold] ${DELETIONS_COUNT} "
fi

if [[ $UNTRACKED_COUNT -gt 0 ]]; then
  STATUS_UNTRACKED="${RESET}#[fg=${THEME[black]},bg=${THEME[background]},bold] ${UNTRACKED_COUNT} "
fi

# Set the status indicator based on the sync mode
case "$SYNC_MODE" in
local_changes)
  REMOTE_STATUS="$RESET#[bg=${THEME[background]},fg=${THEME[bred]},bold]▒ 󱓎"
  ;;
need_push)
  REMOTE_STATUS="$RESET#[bg=${THEME[background]},fg=${THEME[red]},bold]▒ 󰛃"
  ;;
remote_ahead)
  REMOTE_STATUS="$RESET#[bg=${THEME[background]},fg=${THEME[magenta]},bold]▒ 󰛀"
  ;;
*)
  REMOTE_STATUS="$RESET#[bg=${THEME[background]},fg=${THEME[green]},bold]▒ "
  ;;
esac

if [[ -n $BRANCH ]]; then
  echo "$REMOTE_STATUS $RESET$BRANCH $STATUS_CHANGED$STATUS_INSERTIONS$STATUS_DELETIONS$STATUS_UNTRACKED"
fi
