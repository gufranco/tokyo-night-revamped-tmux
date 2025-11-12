#!/usr/bin/env bash
# Verify if the current session is the minimal session
MINIMAL_SESSION_NAME=$(tmux show-option -gv @tokyo-night-tmux_minimal_session 2>/dev/null)
TMUX_SESSION_NAME=$(tmux display-message -p '#S')

if [ "$MINIMAL_SESSION_NAME" = "$TMUX_SESSION_NAME" ]; then
  exit 0
fi

SHOW_NETSPEED=$(tmux show-option -gv @tokyo-night-tmux_show_git)
if [ "$SHOW_NETSPEED" == "0" ]; then
  exit 0
fi

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/../lib/coreutils-compat.sh"
source "$CURRENT_DIR/themes.sh"

cd "$1" || exit 1
RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
STATUS=$(git status --porcelain 2>/dev/null | grep -cE "^(M| M)")

SYNC_MODE=0
NEED_PUSH=0

if [[ ${#BRANCH} -gt 25 ]]; then
  BRANCH="${BRANCH:0:25}…"
fi

STATUS_CHANGED=""
STATUS_INSERTIONS=""
STATUS_DELETIONS=""
STATUS_UNTRACKED=""

if [[ $STATUS -ne 0 ]]; then
  DIFF_COUNTS=($(git diff --numstat 2>/dev/null | awk 'NF==3 {changed+=1; ins+=$1; del+=$2} END {printf("%d %d %d", changed, ins, del)}'))
  CHANGED_COUNT=${DIFF_COUNTS[0]}
  INSERTIONS_COUNT=${DIFF_COUNTS[1]}
  DELETIONS_COUNT=${DIFF_COUNTS[2]}

  SYNC_MODE=1
fi

# Check if we should check untracked files
CHECK_UNTRACKED=$(tmux show-option -gv @tokyo-night-tmux_git_check_untracked 2>/dev/null)
CHECK_UNTRACKED="${CHECK_UNTRACKED:-1}"

UNTRACKED_COUNT=0
if [[ $CHECK_UNTRACKED -eq 1 ]]; then
  UNTRACKED_COUNT="$(git ls-files --other --exclude-standard | wc -l | bc)"
fi

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

# Check if auto-fetch is disabled
DISABLE_AUTO_FETCH=$(tmux show-option -gv @tokyo-night-tmux_git_disable_auto_fetch 2>/dev/null)
FETCH_TIMEOUT=$(tmux show-option -gv @tokyo-night-tmux_git_fetch_timeout 2>/dev/null)
FETCH_TIMEOUT="${FETCH_TIMEOUT:-5}"

# Determine repository sync status
if [[ $SYNC_MODE -eq 0 ]]; then
  NEED_PUSH=$(git log @{push}.. 2>/dev/null | wc -l | bc)
  if [[ $NEED_PUSH -gt 0 ]]; then
    SYNC_MODE=2
  else
    # Only fetch if not disabled
    if [[ "$DISABLE_AUTO_FETCH" != "1" ]] && [[ -f .git/FETCH_HEAD ]]; then
      LAST_FETCH=$(stat -c %Y .git/FETCH_HEAD 2>/dev/null || stat -f %m .git/FETCH_HEAD 2>/dev/null || echo 0)
      NOW=$(date +%s | bc)

      # if 5 minutes have passed since the last fetch
      if [[ $((NOW - LAST_FETCH)) -gt 300 ]]; then
        # Fetch with timeout to prevent hanging on large repos
        timeout "${FETCH_TIMEOUT}s" git fetch --atomic origin --negotiation-tip=HEAD 2>/dev/null &
        FETCH_PID=$!
        
        # Wait for fetch to complete or timeout
        wait $FETCH_PID 2>/dev/null
      fi
    fi

    # Check if the remote branch is ahead of the local branch
    REMOTE_DIFF="$(timeout 2s git diff --numstat "${BRANCH}" "origin/${BRANCH}" 2>/dev/null)"
    if [[ -n $REMOTE_DIFF ]]; then
      SYNC_MODE=3
    fi
  fi
fi

# Set the status indicator based on the sync mode
case "$SYNC_MODE" in
1)
  REMOTE_STATUS="$RESET#[bg=${THEME[background]},fg=${THEME[bred]},bold]▒ 󱓎"
  ;;
2)
  REMOTE_STATUS="$RESET#[bg=${THEME[background]},fg=${THEME[red]},bold]▒ 󰛃"
  ;;
3)
  REMOTE_STATUS="$RESET#[bg=${THEME[background]},fg=${THEME[magenta]},bold]▒ 󰛀"
  ;;
*)
  REMOTE_STATUS="$RESET#[bg=${THEME[background]},fg=${THEME[green]},bold]▒ "
  ;;
esac

if [[ -n $BRANCH ]]; then
  echo "$REMOTE_STATUS $RESET$BRANCH $STATUS_CHANGED$STATUS_INSERTIONS$STATUS_DELETIONS$STATUS_UNTRACKED"
fi
