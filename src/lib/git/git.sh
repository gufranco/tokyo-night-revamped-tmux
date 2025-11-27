#!/usr/bin/env bash

is_git_repository() {
  git --no-optional-locks rev-parse --git-dir &>/dev/null
}

get_git_branch() {
  git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null
}

get_git_branch_truncated() {
  local max_length="${1:-25}"
  local branch
  branch="$(get_git_branch)"
  
  if [[ ${#branch} -gt $max_length ]]; then
    echo "${branch:0:${max_length}}…"
  else
    echo "${branch}"
  fi
}

get_git_modified_count() {
  git --no-optional-locks status --porcelain 2>/dev/null | grep -cE "^(M| M)" || echo "0"
}

get_git_diff_stats() {
  git --no-optional-locks diff --numstat 2>/dev/null | awk 'NF==3 {changed+=1; ins+=$1; del+=$2} END {printf("%d %d %d", changed+0, ins+0, del+0)}'
}

get_git_untracked_count() {
  local check_untracked="${1:-1}"
  
  if [[ "${check_untracked}" == "0" ]]; then
    echo "0"
    return
  fi
  
  git --no-optional-locks status --porcelain --untracked-files=normal 2>/dev/null | grep -c "^??" || echo "0"
}

get_git_commits_to_push() {
  local count
  count=$(git --no-optional-locks log @{push}.. 2>/dev/null | grep -c "^commit" 2>/dev/null || echo "0")
  echo "${count}"
}

is_remote_ahead() {
  local branch
  branch="$(get_git_branch)"
  
  if [[ -z "${branch}" ]]; then
    return 1
  fi
  
  local diff
  diff="$(git --no-optional-locks diff --numstat "${branch}" "origin/${branch}" 2>/dev/null)"
  
  [[ -n "${diff}" ]]
}

get_seconds_since_last_fetch() {
  local fetch_head=".git/FETCH_HEAD"
  
  if [[ ! -f "${fetch_head}" ]]; then
    echo "999999"
    return
  fi
  
  local last_fetch current_time
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    last_fetch=$(stat -f "%m" "${fetch_head}" 2>/dev/null)
  else
    last_fetch=$(stat -c "%Y" "${fetch_head}" 2>/dev/null)
  fi
  
  [[ ! "$last_fetch" =~ ^[0-9]+$ ]] && last_fetch=0
  
  current_time=$(date +%s)
  
  echo "$((current_time - last_fetch))"
}

maybe_fetch_from_remote() {
  local interval="${1:-300}"
  local seconds_since_fetch
  seconds_since_fetch="$(get_seconds_since_last_fetch)"
  
  if (( seconds_since_fetch > interval )); then
    git --no-optional-locks fetch --atomic origin --negotiation-tip=HEAD 2>/dev/null &
    return 0
  fi
  
  return 1
}

get_repository_sync_status() {
  local modified_count
  modified_count="$(get_git_modified_count)"
  
  if [[ "$modified_count" =~ ^[0-9]+$ ]] && (( modified_count > 0 )); then
    echo "local_changes"
    return
  fi
  
  local commits_to_push
  commits_to_push="$(get_git_commits_to_push)"
  if [[ "$commits_to_push" =~ ^[0-9]+$ ]] && (( commits_to_push > 0 )); then
    echo "need_push"
    return
  fi
  
  maybe_fetch_from_remote 300
  
  if is_remote_ahead; then
    echo "remote_ahead"
    return
  fi
  
  echo "clean"
}

get_git_provider() {
  local remote_url
  remote_url="$(git config remote.origin.url 2>/dev/null)"
  
  if [[ -z "${remote_url}" ]]; then
    return
  fi
  
  if [[ "${remote_url}" =~ ^https://([^/]+)/ ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi
  
  if [[ "${remote_url}" =~ @([^:]+): ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi
  
  echo "${remote_url}" | awk -F '@|:' '{print $2}'
}

export -f is_git_repository
export -f get_git_branch
export -f get_git_branch_truncated
export -f get_git_modified_count
export -f get_git_diff_stats
export -f get_git_untracked_count
export -f get_git_commits_to_push
export -f is_remote_ahead
export -f get_seconds_since_last_fetch
export -f maybe_fetch_from_remote
export -f get_repository_sync_status
export -f get_git_provider

