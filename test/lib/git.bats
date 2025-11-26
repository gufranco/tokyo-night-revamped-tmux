#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/git.sh"
}

teardown() {
  cleanup_test_environment
}

@test "git.sh - is_git_repository returns true for repository valid" {
  export MOCK_GIT_REPO=1
  if is_git_repository; then
    true
  else
    false
  fi
}

@test "git.sh - get_git_branch_truncated truncates branch long" {
  export MOCK_GIT_BRANCH="uma-branch-muito-long-que-should-ser-truncates"
  result=$(get_git_branch_truncated "25")
  [[ ${#result} -le 26 ]]  # 25 chars + ellipsis
}

@test "git.sh - get_git_diff_stats returns statistics" {
  export MOCK_GIT_DIFF_NUMSTAT="10  5  file1.txt
20 10 file2.txt"
  result=$(get_git_diff_stats)
  [[ -n "$result" ]]
  [[ "$result" =~ ^[0-9]+ ]]
}

@test "git.sh - get_git_untracked_count returns 0 when disabled" {
  result=$(get_git_untracked_count "0")
  [[ "$result" == "0" ]]
}

@test "git.sh - get_git_untracked_count returns count when enabled" {
  export MOCK_GIT_UNTRACKED_FILES="file1.txt
file2.txt"
  export MOCK_WC_LINES="2"
  result=$(get_git_untracked_count "1")
  [[ -n "$result" ]]
}

@test "git.sh - get_git_commits_to_push returns count" {
  export MOCK_GIT_LOG_OUTPUT="commit abc123
commit def456"
  result=$(get_git_commits_to_push)
  [[ -n "$result" ]]
}

@test "git.sh - is_remote_ahead returns false when not there are difference" {
  export MOCK_GIT_BRANCH="main"
  export MOCK_GIT_DIFF_OUTPUT=""
  if ! is_remote_ahead; then
    true
  else
    false
  fi
}

@test "git.sh - is_remote_ahead returns false when branch empty" {
  export MOCK_GIT_BRANCH=""
  if ! is_remote_ahead; then
    true
  else
    false
  fi
}

@test "git.sh - get_repository_sync_status returns local_changes when there are modifications" {
  export MOCK_GIT_STATUS="M  file1.txt"
  result=$(get_repository_sync_status)
  [[ "$result" == "local_changes" ]]
}

@test "git.sh - get_git_provider returns github for URL GitHub" {
  export MOCK_GIT_REMOTE_URL="https://github.with/user/repo.git"
  result=$(get_git_provider)
  [[ "$result" == "github.with" ]]
}

@test "git.sh - get_git_provider returns gitlab for URL GitLab" {
  export MOCK_GIT_REMOTE_URL="https://gitlab.with/user/repo.git"
  result=$(get_git_provider)
  [[ "$result" == "gitlab.with" ]]
}

@test "git.sh - get_git_provider returns provider for URL SSH" {
  export MOCK_GIT_REMOTE_URL="git@github.with:user/repo.git"
  result=$(get_git_provider)
  [[ -n "$result" ]]
}

@test "git.sh - get_git_provider returns empty when remote not set" {
  export MOCK_GIT_REMOTE_URL=""
  result=$(get_git_provider)
  [[ -z "$result" ]]
}

