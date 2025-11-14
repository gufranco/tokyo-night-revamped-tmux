#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/coreutils-compat.sh"
source "${LIB_DIR}/constants.sh"
source "${LIB_DIR}/themes.sh"
source "${LIB_DIR}/color-scale.sh"

MINIMAL_SESSION=$(tmux show-option -gv @tokyo-night-tmux_minimal_session 2>/dev/null)
CURRENT_SESSION=$(tmux display-message -p '#S')

[[ -n "$MINIMAL_SESSION" ]] && [[ "$MINIMAL_SESSION" == "$CURRENT_SESSION" ]] && exit 0

SHOW_GIT=$(tmux show-option -gv @tokyo-night-tmux_show_git 2>/dev/null)
[[ "$SHOW_GIT" == "0" ]] && exit 0

cd "$1" || exit 0

git rev-parse --git-dir &>/dev/null || exit 0

CHECK_UNTRACKED=$(tmux show-option -gv @tokyo-night-tmux_git_untracked 2>/dev/null)
CHECK_UNTRACKED="${CHECK_UNTRACKED:-1}"

SHOW_WEB=$(tmux show-option -gv @tokyo-night-tmux_git_web 2>/dev/null)
SHOW_WEB="${SHOW_WEB:-1}"

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
fi

if [[ $CHECK_UNTRACKED -eq 1 ]]; then
  UNTRACKED=$(git ls-files --other --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
fi

OUTPUT="${COLOR_CYAN}░ ⎇${COLOR_RESET} ${BRANCH}"

if [[ $CHANGED -gt 0 ]]; then
  changed_color=$(get_git_changes_color "$CHANGED")
  OUTPUT="${OUTPUT} ${changed_color}󰄴 ${CHANGED}${COLOR_RESET}"
fi

if [[ $INSERTIONS -gt 0 ]]; then
  insertions_color=$(get_git_lines_color "$INSERTIONS")
  OUTPUT="${OUTPUT} ${insertions_color}󰐕 ${INSERTIONS}${COLOR_RESET}"
fi

if [[ $DELETIONS -gt 0 ]]; then
  deletions_color=$(get_git_lines_color "$DELETIONS")
  OUTPUT="${OUTPUT} ${deletions_color}󰍵 ${DELETIONS}${COLOR_RESET}"
fi

if [[ $UNTRACKED -gt 0 ]]; then
  untracked_color=$(get_git_untracked_color "$UNTRACKED")
  OUTPUT="${OUTPUT} ${untracked_color}󰋗 ${UNTRACKED}${COLOR_RESET}"
fi

if [[ $SHOW_WEB -eq 1 ]]; then
  REMOTE_URL=$(git config remote.origin.url 2>/dev/null)

  if [[ -n "$REMOTE_URL" ]]; then
    PROVIDER=""

    if [[ "$REMOTE_URL" =~ github\.com ]]; then
      PROVIDER="github"
      PROVIDER_ICON=""
    elif [[ "$REMOTE_URL" =~ gitlab\.com ]]; then
      PROVIDER="gitlab"
      PROVIDER_ICON=""
    fi

    if [[ -n "$PROVIDER" ]]; then
      PR_COUNT=0
      REVIEW_COUNT=0
      ISSUE_COUNT=0
      BUG_COUNT=0

      if [[ "$PROVIDER" == "github" ]] && command -v gh &>/dev/null; then
        PR_COUNT=$(gh pr list --json number --jq 'length' 2>/dev/null | head -1 | tr -d '\n ' || echo "0")
        REVIEW_COUNT=$(gh pr status --json reviewRequests --jq '.needsReview | length' 2>/dev/null | head -1 | tr -d '\n ' || echo "0")
        ISSUE_JSON=$(gh issue list --json "assignees,labels" --assignee @me 2>/dev/null || echo "[]")
        ISSUE_COUNT=$(echo "$ISSUE_JSON" | jq 'length' 2>/dev/null | head -1 | tr -d '\n ' || echo "0")
        BUG_COUNT=$(echo "$ISSUE_JSON" | jq 'map(select(.labels[]? | .name == "bug")) | length' 2>/dev/null | head -1 | tr -d '\n ' || echo "0")

        [[ ! "$PR_COUNT" =~ ^[0-9]+$ ]] && PR_COUNT=0
        [[ ! "$REVIEW_COUNT" =~ ^[0-9]+$ ]] && REVIEW_COUNT=0
        [[ ! "$ISSUE_COUNT" =~ ^[0-9]+$ ]] && ISSUE_COUNT=0
        [[ ! "$BUG_COUNT" =~ ^[0-9]+$ ]] && BUG_COUNT=0

        ISSUE_COUNT=$((ISSUE_COUNT - BUG_COUNT))
      elif [[ "$PROVIDER" == "gitlab" ]] && command -v glab &>/dev/null; then
        PR_COUNT=$(glab mr list 2>/dev/null | grep -cE "^!" || echo "0")
        REVIEW_COUNT=$(glab mr list --reviewer=@me 2>/dev/null | grep -cE "^!" || echo "0")
        ISSUE_COUNT=$(glab issue list 2>/dev/null | grep -cE "^#" || echo "0")
        BUG_COUNT=0

        [[ ! "$PR_COUNT" =~ ^[0-9]+$ ]] && PR_COUNT=0
        [[ ! "$REVIEW_COUNT" =~ ^[0-9]+$ ]] && REVIEW_COUNT=0
        [[ ! "$ISSUE_COUNT" =~ ^[0-9]+$ ]] && ISSUE_COUNT=0
      fi

      pr_color=$(get_git_pr_color "$PR_COUNT")
      OUTPUT="${OUTPUT} ${pr_color}${PROVIDER_ICON}󰊤 ${PR_COUNT}${COLOR_RESET}"
      
      review_color=$(get_git_review_color "$REVIEW_COUNT")
      OUTPUT="${OUTPUT} ${review_color}󰭎 ${REVIEW_COUNT}${COLOR_RESET}"
      
      issue_color=$(get_git_issue_color "$ISSUE_COUNT")
      OUTPUT="${OUTPUT} ${issue_color}󰀨 ${ISSUE_COUNT}${COLOR_RESET}"
      
      bug_color=$(get_git_bug_color "$BUG_COUNT")
      OUTPUT="${OUTPUT} ${bug_color}󰃤 ${BUG_COUNT}${COLOR_RESET}"
    fi
  fi
fi

echo "${OUTPUT} "
