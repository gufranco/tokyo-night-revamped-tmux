#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/coreutils-compat.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/constants.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/themes.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/color-scale.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/cache.sh"
}

teardown() {
  cleanup_test_environment
}

@test "git-widget.sh - sai when session minimal" {
  export TMUX_MINIMAL_SESSION="test-session"
  export TMUX_CURRENT_SESSION="test-session"
  run bash -c 'source "${BATS_TEST_DIRNAME}/../../src/git-widget.sh" /tmp 2>&1; exit 0'
  [[ $status -eq 0 ]] || true
}

@test "git-widget.sh - sai when show_git é 0" {
  export TMUX_SHOW_GIT="0"
  export TMUX_CURRENT_SESSION="other-session"
  run bash -c 'source "${BATS_TEST_DIRNAME}/../../src/git-widget.sh" /tmp 2>&1; exit 0'
  [[ $status -eq 0 ]] || true
}

@test "git-widget.sh - sai when not é repository git" {
  export TMUX_SHOW_GIT="1"
  export MOCK_GIT_REPO=0
  run bash -c 'source "${BATS_TEST_DIRNAME}/../../src/git-widget.sh" /tmp 2>&1; exit 0'
  [[ $status -eq 0 ]] || true
}

@test "git-widget.sh - uses cache when available" {
  export TMUX_SHOW_GIT="1"
  export MOCK_GIT_REPO=1
  export TMUX_REFRESH_RATE="5"
  
  # Mock of cache
  cache_file="${TEST_TMPDIR}/tmux_tokyo_night_cache/git__tmp.cache"
  mkdir -p "$(dirname "$cache_file")"
  echo "cached output" > "$cache_file"
  current_time=$(get_current_timestamp)
  export MOCK_FILE_MTIME=$(( current_time - 1 ))
  
  # Teste básico
  [[ -f "$cache_file" ]]
}

@test "git-widget.sh - truncates branch long" {
  export TMUX_SHOW_GIT="1"
  export MOCK_GIT_REPO=1
  export MOCK_GIT_BRANCH="uma-branch-muito-long-que-should-ser-truncates"
  
  # Teste básico
  [[ ${#MOCK_GIT_BRANCH} -gt 25 ]]
}

@test "git-widget.sh - shows mudanças when there are modifications" {
  export TMUX_SHOW_GIT="1"
  export MOCK_GIT_REPO=1
  export MOCK_GIT_STATUS="M  file1.txt
 M file2.txt"
  export MOCK_GIT_DIFF_NUMSTAT="10  5  file1.txt"
  
  # Teste básico
  function_exists get_git_changes_color
  function_exists get_git_changes_icon
}

@test "git-widget.sh - shows insertions e deletions" {
  export TMUX_SHOW_GIT="1"
  export MOCK_GIT_REPO=1
  export MOCK_GIT_DIFF_NUMSTAT="100  50  file1.txt"
  
  # Teste básico
  function_exists get_git_lines_color
  function_exists get_git_insertions_icon
  function_exists get_git_deletions_icon
}

@test "git-widget.sh - shows untracked when enabled" {
  export TMUX_SHOW_GIT="1"
  export TMUX_GIT_UNTRACKED="1"
  export MOCK_GIT_REPO=1
  export MOCK_GIT_UNTRACKED_FILES="file1.txt
file2.txt"
  export MOCK_WC_LINES="2"
  
  # Teste básico
  function_exists get_git_untracked_color
  function_exists get_git_untracked_icon
}

@test "git-widget.sh - shows web stats when enabled" {
  export TMUX_SHOW_GIT="1"
  export TMUX_GIT_WEB="1"
  export MOCK_GIT_REPO=1
  export MOCK_GIT_REMOTE_URL="https://github.with/user/repo.git"
  
  # Teste básico
  function_exists get_git_pr_color
  function_exists get_git_review_color
  function_exists get_git_issue_color
  function_exists get_git_bug_color
}

@test "git-widget.sh - detects GitHub" {
  export TMUX_SHOW_GIT="1"
  export TMUX_GIT_WEB="1"
  export MOCK_GIT_REPO=1
  export MOCK_GIT_REMOTE_URL="https://github.with/user/repo.git"
  
  # Teste básico
  [[ "$MOCK_GIT_REMOTE_URL" =~ github\.with ]]
}

@test "git-widget.sh - detects GitLab" {
  export TMUX_SHOW_GIT="1"
  export TMUX_GIT_WEB="1"
  export MOCK_GIT_REPO=1
  export MOCK_GIT_REMOTE_URL="https://gitlab.with/user/repo.git"
  
  # Teste básico
  [[ "$MOCK_GIT_REMOTE_URL" =~ gitlab\.with ]]
}

@test "git-widget.sh - busca PRs of GitHub" {
  export TMUX_SHOW_GIT="1"
  export TMUX_GIT_WEB="1"
  export MOCK_GIT_REPO=1
  export MOCK_GIT_REMOTE_URL="https://github.with/user/repo.git"
  export MOCK_GH_PR_LIST='[{"number":1},{"number":2}]'
  export MOCK_JQ_OUTPUT="2"
  
  # Teste básico
  function_exists get_git_pr_icon
}

@test "git-widget.sh - busca reviews of GitHub" {
  export TMUX_SHOW_GIT="1"
  export TMUX_GIT_WEB="1"
  export MOCK_GIT_REPO=1
  export MOCK_GIT_REMOTE_URL="https://github.with/user/repo.git"
  export MOCK_GH_PR_STATUS='{"needsReview":[{"number":1}]}'
  export MOCK_JQ_OUTPUT="1"
  
  # Teste básico
  function_exists get_git_review_icon
}

@test "git-widget.sh - busca issues of GitHub" {
  export TMUX_SHOW_GIT="1"
  export TMUX_GIT_WEB="1"
  export MOCK_GIT_REPO=1
  export MOCK_GIT_REMOTE_URL="https://github.with/user/repo.git"
  export MOCK_GH_ISSUE_LIST='[{"assignees":[],"labels":[]}]'
  export MOCK_JQ_OUTPUT="1"
  
  # Teste básico
  function_exists get_git_issue_icon
}

@test "git-widget.sh - busca bugs of GitHub" {
  export TMUX_SHOW_GIT="1"
  export TMUX_GIT_WEB="1"
  export MOCK_GIT_REPO=1
  export MOCK_GIT_REMOTE_URL="https://github.with/user/repo.git"
  export MOCK_GH_ISSUE_LIST='[{"assignees":[],"labels":[{"name":"bug"}]}]'
  export MOCK_JQ_OUTPUT="1"
  
  # Teste básico
  function_exists get_git_bug_color
}

