#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${SCRIPT_DIR}/themes.sh"

MINIMAL_SESSION=$(tmux show-option -gv @tokyo-night-tmux_minimal_session 2>/dev/null)
CURRENT_SESSION=$(tmux display-message -p '#S')

[[ -n "$MINIMAL_SESSION" ]] && [[ "$MINIMAL_SESSION" == "$CURRENT_SESSION" ]] && exit 0

SHOW_GIT_WEB=$(tmux show-option -gv @tokyo-night-tmux_show_git_web 2>/dev/null)
[[ "$SHOW_GIT_WEB" == "0" ]] && exit 0

cd "$1" || exit 0

git rev-parse --git-dir &>/dev/null || exit 0

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

REMOTE_URL=$(git config remote.origin.url 2>/dev/null)
[[ -z "$REMOTE_URL" ]] && exit 0

if [[ "$REMOTE_URL" =~ github\.com ]]; then
  PROVIDER="github"
elif [[ "$REMOTE_URL" =~ gitlab\.com ]]; then
  PROVIDER="gitlab"
else
  exit 0
fi

PR_COUNT=0
REVIEW_COUNT=0
ISSUE_COUNT=0
BUG_COUNT=0

if [[ "$PROVIDER" == "github" ]]; then
  command -v gh &>/dev/null || exit 0
  
  PR_COUNT=$(gh pr list --json number --jq 'length' 2>/dev/null | head -1 | tr -d '\n ' || echo "0")
  REVIEW_COUNT=$(gh pr status --json reviewRequests --jq '.needsReview | length' 2>/dev/null | head -1 | tr -d '\n ' || echo "0")
  
  ISSUE_JSON=$(gh issue list --json "assignees,labels" --assignee @me 2>/dev/null || echo "[]")
  ISSUE_COUNT=$(echo "$ISSUE_JSON" | jq 'length' 2>/dev/null | head -1 | tr -d '\n ' || echo "0")
  BUG_COUNT=$(echo "$ISSUE_JSON" | jq 'map(select(.labels[]? | .name == "bug")) | length' 2>/dev/null | head -1 | tr -d '\n ' || echo "0")
  
  [[ ! "$ISSUE_COUNT" =~ ^[0-9]+$ ]] && ISSUE_COUNT=0
  [[ ! "$BUG_COUNT" =~ ^[0-9]+$ ]] && BUG_COUNT=0
  [[ ! "$PR_COUNT" =~ ^[0-9]+$ ]] && PR_COUNT=0
  [[ ! "$REVIEW_COUNT" =~ ^[0-9]+$ ]] && REVIEW_COUNT=0
  
  ISSUE_COUNT=$((ISSUE_COUNT - BUG_COUNT))
  
  PROVIDER_ICON="#[fg=${THEME[foreground]}] "
elif [[ "$PROVIDER" == "gitlab" ]]; then
  command -v glab &>/dev/null || exit 0
  
  PR_COUNT=$(glab mr list 2>/dev/null | grep -cE "^!" || echo "0")
  REVIEW_COUNT=$(glab mr list --reviewer=@me 2>/dev/null | grep -cE "^!" || echo "0")
  ISSUE_COUNT=$(glab issue list 2>/dev/null | grep -cE "^#" || echo "0")
  BUG_COUNT=0
  
  [[ ! "$PR_COUNT" =~ ^[0-9]+$ ]] && PR_COUNT=0
  [[ ! "$REVIEW_COUNT" =~ ^[0-9]+$ ]] && REVIEW_COUNT=0
  [[ ! "$ISSUE_COUNT" =~ ^[0-9]+$ ]] && ISSUE_COUNT=0
  
  PROVIDER_ICON="#[fg=#fc6d26] "
fi

OUTPUT="${RESET}#[fg=${THEME[cyan]},bg=default]░${RESET} ${PROVIDER_ICON}"
OUTPUT="${OUTPUT}#[fg=${THEME[green]}]󰊤 ${PR_COUNT}"
OUTPUT="${OUTPUT} #[fg=${THEME[yellow]}]󰭎 ${REVIEW_COUNT}"
OUTPUT="${OUTPUT} #[fg=${THEME[magenta]}]󰀨 ${ISSUE_COUNT}"
OUTPUT="${OUTPUT} #[fg=${THEME[red]}]󰃤 ${BUG_COUNT}"

echo "${OUTPUT} "
