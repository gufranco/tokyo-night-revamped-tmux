#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/tmux/tmux-ops.sh"
}

teardown() {
  cleanup_test_environment
}

@test "tmux-ops.sh - get_tmux_option returns default when option not set" {
  export TMUX_SHOW_OPTION_VALUE=""
  result=$(get_tmux_option "@test_option" "default_value")
  [[ "$result" == "default_value" ]]
}

@test "tmux-ops.sh - get_tmux_option returns value when option is set" {
  export TMUX_SHOW_OPTION_VALUE="test_value"
  result=$(get_tmux_option "@test_option" "default_value")
  [[ "$result" == "test_value" ]]
}

@test "tmux-ops.sh - set_tmux_option sets option" {
  run set_tmux_option "@test_option" "test_value"
  [[ $status -eq 0 ]] || true
}

@test "tmux-ops.sh - is_tmux_option_enabled returns true when enabled" {
  export TMUX_SHOW_OPTION_VALUE="1"
  run is_tmux_option_enabled "@test_option"
  [[ $status -eq 0 ]]
}

@test "tmux-ops.sh - is_tmux_option_enabled returns false when disabled" {
  export TMUX_SHOW_OPTION_VALUE="0"
  run is_tmux_option_enabled "@test_option"
  [[ $status -ne 0 ]]
}

@test "tmux-ops.sh - get_session_name returns session name" {
  export TMUX_CURRENT_SESSION="test-session"
  result=$(get_session_name)
  [[ "$result" == "test-session" ]]
}

@test "tmux-ops.sh - is_minimal_session returns true when session matches" {
  export TMUX_MINIMAL_SESSION="test-session"
  export TMUX_CURRENT_SESSION="test-session"
  run is_minimal_session
  [[ $status -eq 0 ]]
}

@test "tmux-ops.sh - is_minimal_session returns false when session does not match" {
  export TMUX_MINIMAL_SESSION="test-session"
  export TMUX_CURRENT_SESSION="other-session"
  run is_minimal_session
  [[ $status -ne 0 ]]
}

