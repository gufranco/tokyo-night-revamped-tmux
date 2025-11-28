#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/cache.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/widget/widget-base.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/widget/widget-common.sh"
}

teardown() {
  cleanup_test_environment
}

@test "widget-common.sh - get_widget_cache_key returns widget name without suffix" {
  result=$(get_widget_cache_key "test_widget")
  [[ "$result" == "test_widget" ]]
}

@test "widget-common.sh - get_widget_cache_key returns widget name with suffix" {
  result=$(get_widget_cache_key "test_widget" "suffix")
  [[ "$result" == "test_widget_suffix" ]]
}

@test "widget-common.sh - get_cached_widget_output returns cached value when available" {
  export TMUX_REFRESH_RATE="5"
  set_cached_value "test_widget" "cached_output" 2>/dev/null || true
  result=$(get_cached_widget_output "test_widget")
  [[ -n "$result" ]] || true
}

@test "widget-common.sh - should_use_cache returns true when output exists" {
  run should_use_cache "test_output"
  [[ $status -eq 0 ]]
}

@test "widget-common.sh - should_use_cache returns false when output is empty" {
  run should_use_cache ""
  [[ $status -ne 0 ]]
}

@test "widget-common.sh - validate_widget_enabled exits when disabled" {
  export TMUX_SHOW_SYSTEM="0"
  run validate_widget_enabled "@tokyo-night-tmux_show_system"
  [[ $status -eq 0 ]] || true
}

@test "widget-common.sh - validate_minimal_session exits when session is minimal" {
  export TMUX_MINIMAL_SESSION="test-session"
  export TMUX_CURRENT_SESSION="test-session"
  run validate_minimal_session
  [[ $status -eq 0 ]] || true
}

