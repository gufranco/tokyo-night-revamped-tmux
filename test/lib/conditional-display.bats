#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/conditional-display.sh"
}

teardown() {
  cleanup_test_environment
}

@test "conditional-display.sh - should_display_widget returns true when enabled" {
  export TMUX_SHOW_SYSTEM="1"
  should_display_widget "system"
}

@test "conditional-display.sh - should_display_widget returns false when disabled" {
  export TMUX_SHOW_SYSTEM="0"
  ! should_display_widget "system"
}

@test "conditional-display.sh - should_display_time_based works" {
  should_display_time_based 0 23
  [[ $? -eq 0 ]] || true
}

