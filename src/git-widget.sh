#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/widget/widget-loader.sh"
source "${LIB_DIR}/tmux/tmux-ops.sh"
source "${LIB_DIR}/widget/widget-common.sh"
source "${LIB_DIR}/widget/widget-config.sh"

load_widget_dependencies "git"

validate_minimal_session
validate_widget_enabled "@yoru_show_git"

cd "$1" || exit 0
git rev-parse --git-dir &>/dev/null || exit 0

cache_key="git_$(pwd | sed 's/\//_/g')"
cached_output=$(get_cached_widget_output "git" "$cache_key")
should_use_cache "$cached_output" && echo "$cached_output" && exit 0

CHECK_UNTRACKED=$(is_widget_feature_enabled "@yoru_git_untracked" "1")
SHOW_WEB=$(is_widget_feature_enabled "@yoru_git_web" "1")
SHOW_STASH=$(is_widget_feature_enabled "@yoru_git_stash" "0")
SHOW_AHEAD_BEHIND=$(is_widget_feature_enabled "@yoru_git_ahead_behind" "0")
SHOW_LAST_COMMIT=$(is_widget_feature_enabled "@yoru_git_last_commit" "0")

main() {
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
  UNTRACKED=$(git ls-files --other --exclude-standard 2>/dev/null | wc -l)
  UNTRACKED="${UNTRACKED// /}"
fi

OUTPUT="${COLOR_CYAN}░ ⎇${COLOR_RESET} ${BRANCH}"

if [[ $CHANGED -gt 0 ]]; then
  changed_color=$(get_git_changes_color "$CHANGED")
  changed_icon=$(get_git_changes_icon "$CHANGED")
  OUTPUT="${OUTPUT} ${changed_color}${changed_icon} ${CHANGED}${COLOR_RESET}"
fi

if [[ $INSERTIONS -gt 0 ]]; then
  insertions_color=$(get_git_lines_color "$INSERTIONS")
  insertions_icon=$(get_git_insertions_icon "$INSERTIONS")
  OUTPUT="${OUTPUT} ${insertions_color}${insertions_icon} ${INSERTIONS}${COLOR_RESET}"
fi

if [[ $DELETIONS -gt 0 ]]; then
  deletions_color=$(get_git_lines_color "$DELETIONS")
  deletions_icon=$(get_git_deletions_icon "$DELETIONS")
  OUTPUT="${OUTPUT} ${deletions_color}${deletions_icon} ${DELETIONS}${COLOR_RESET}"
fi

if [[ $UNTRACKED -gt 0 ]]; then
  untracked_color=$(get_git_untracked_color "$UNTRACKED")
  untracked_icon=$(get_git_untracked_icon "$UNTRACKED")
  OUTPUT="${OUTPUT} ${untracked_color}${untracked_icon} ${UNTRACKED}${COLOR_RESET}"
fi

if [[ $SHOW_STASH -eq 1 ]]; then
  stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  if [[ -n "$stash_count" ]] && [[ "$stash_count" =~ ^[0-9]+$ ]] && [[ $stash_count -gt 0 ]]; then
    local stash_color
    if (( stash_count >= 5 )); then
      stash_color="${COLOR_YELLOW}"
    else
      stash_color="${COLOR_CYAN}"
    fi
    OUTPUT="${OUTPUT} ${stash_color}${ICON_STASH} ${stash_count}${COLOR_RESET}"
  fi
fi

if [[ $SHOW_AHEAD_BEHIND -eq 1 ]]; then
  ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
  behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")

  if [[ -n "$ahead" ]] && [[ "$ahead" =~ ^[0-9]+$ ]] && [[ $ahead -gt 0 ]]; then
    OUTPUT="${OUTPUT} ${COLOR_GREEN}↑${ahead}${COLOR_RESET}"
  fi

  if [[ -n "$behind" ]] && [[ "$behind" =~ ^[0-9]+$ ]] && [[ $behind -gt 0 ]]; then
    OUTPUT="${OUTPUT} ${COLOR_YELLOW}↓${behind}${COLOR_RESET}"
  fi
fi

if [[ $SHOW_LAST_COMMIT -eq 1 ]]; then
  last_commit_time=$(git log -1 --format=%ct 2>/dev/null)
  if [[ -n "$last_commit_time" ]] && [[ "$last_commit_time" =~ ^[0-9]+$ ]]; then
    current_time=$(date +%s)
    time_diff=$(( current_time - last_commit_time ))

    local time_str
    if (( time_diff < 3600 )); then
      time_str="${time_diff}m"
    elif (( time_diff < 86400 )); then
      time_str="$(( time_diff / 3600 ))h"
    else
      time_str="$(( time_diff / 86400 ))d"
    fi

    OUTPUT="${OUTPUT} ${COLOR_CYAN}${ICON_COMMIT} ${time_str}${COLOR_RESET}"
  fi
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

      if [[ "$PROVIDER" == "github" ]] && command -v gh &>/dev/null && command -v jq &>/dev/null; then
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
      pr_icon=$(get_git_pr_icon "$PR_COUNT")
      OUTPUT="${OUTPUT} ${pr_color}${PROVIDER_ICON}${pr_icon} ${PR_COUNT}${COLOR_RESET}"

      review_color=$(get_git_review_color "$REVIEW_COUNT")
      review_icon=$(get_git_review_icon "$REVIEW_COUNT")
      OUTPUT="${OUTPUT} ${review_color}${review_icon} ${REVIEW_COUNT}${COLOR_RESET}"

      issue_color=$(get_git_issue_color "$ISSUE_COUNT")
      issue_icon=$(get_git_issue_icon "$ISSUE_COUNT")
      OUTPUT="${OUTPUT} ${issue_color}${issue_icon} ${ISSUE_COUNT}${COLOR_RESET}"

      bug_color=$(get_git_bug_color "$BUG_COUNT")
      OUTPUT="${OUTPUT} ${bug_color}󰃤 ${BUG_COUNT}${COLOR_RESET}"
    fi
  fi
fi

  tooltip_text=$(generate_git_tooltip)
  set_widget_tooltip "git" "$tooltip_text"

  RESULT="${OUTPUT} "
  set_cached_value "$cache_key" "$RESULT"
  echo "$RESULT"
}

main
