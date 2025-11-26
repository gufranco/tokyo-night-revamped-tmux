#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/tmux-config.sh"
}

teardown() {
  cleanup_test_environment
}

@test "tmux-config.sh - get_tmux_option returns value when set" {
  export TMUX_SHOW_SYSTEM="1"
  result=$(get_tmux_option "@tokyo-night-tmux_show_system" "0")
  [[ "$result" == "1" ]]
}

@test "tmux-config.sh - is_option_enabled returns true for 1" {
  export TMUX_SHOW_SYSTEM="1"
  if is_option_enabled "@tokyo-night-tmux_show_system"; then
    true
  else
    false
  fi
}

@test "tmux-config.sh - is_option_enabled returns true for true" {
  export TMUX_SHOW_SYSTEM="true"
  if is_option_enabled "@tokyo-night-tmux_show_system"; then
    true
  else
    false
  fi
}

@test "tmux-config.sh - is_option_enabled returns false for 0" {
  export TMUX_SHOW_SYSTEM="0"
  if ! is_option_enabled "@tokyo-night-tmux_show_system"; then
    true
  else
    false
  fi
}

@test "tmux-config.sh - should_show_widget calls is_option_enabled" {
  export TMUX_SHOW_SYSTEM="1"
  if should_show_widget "@tokyo-night-tmux_show_system"; then
    true
  else
    false
  fi
}

@test "tmux-config.sh - get_numeric_option returns value valid" {
  export TMUX_REFRESH_RATE="10"
  result=$(get_numeric_option "@tokyo-night-tmux_refresh_rate" "5")
  [[ "$result" == "10" ]]
}

@test "tmux-config.sh - get_numeric_option returns default for value invalid" {
  export TMUX_REFRESH_RATE="abc"
  result=$(get_numeric_option "@tokyo-night-tmux_refresh_rate" "5")
  [[ "$result" == "5" ]]
}

@test "tmux-config.sh - get_numeric_option applies minimum" {
  export TMUX_REFRESH_RATE="0"
  result=$(get_numeric_option "@tokyo-night-tmux_refresh_rate" "5" "1")
  [[ "$result" == "1" ]]
}

@test "tmux-config.sh - get_numeric_option applies maximum" {
  export TMUX_REFRESH_RATE="1000"
  result=$(get_numeric_option "@tokyo-night-tmux_refresh_rate" "5" "1" "100")
  [[ "$result" == "100" ]]
}

@test "tmux-config.sh - get_numeric_option keeps value dentro of limits" {
  export TMUX_REFRESH_RATE="50"
  result=$(get_numeric_option "@tokyo-night-tmux_refresh_rate" "5" "1" "100")
  [[ "$result" == "50" ]]
}

