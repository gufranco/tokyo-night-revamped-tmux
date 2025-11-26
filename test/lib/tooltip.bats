#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/tooltip.sh"
  mkdir -p /tmp/tmux_tokyo_night_tooltips 2>/dev/null
}

teardown() {
  cleanup_test_environment
  rm -rf /tmp/tmux_tokyo_night_tooltips 2>/dev/null || true
}

@test "tooltip.sh - set_widget_tooltip stores tooltip" {
  set_widget_tooltip "test_widget" "Test tooltip content"
  result=$(get_widget_tooltip "test_widget")
  [[ "$result" == "Test tooltip content" ]]
}

@test "tooltip.sh - get_widget_tooltip returns empty for non-existent widget" {
  result=$(get_widget_tooltip "non_existent")
  [[ -z "$result" ]]
}

@test "tooltip.sh - generate_system_tooltip works" {
  export TMUX_SHOW_SYSTEM="1"
  export TMUX_SYSTEM_CPU="1"
  result=$(generate_system_tooltip)
  [[ -n "$result" ]]
}

@test "tooltip.sh - generate_git_tooltip works" {
  export TMUX_SHOW_GIT="1"
  result=$(generate_git_tooltip)
  [[ -n "$result" ]]
}

@test "tooltip.sh - generate_network_tooltip works" {
  export TMUX_SHOW_NETSPEED="1"
  result=$(generate_network_tooltip)
  [[ -n "$result" ]]
}

@test "tooltip.sh - generate_context_tooltip works" {
  export TMUX_SHOW_CONTEXT="1"
  result=$(generate_context_tooltip)
  [[ -n "$result" ]]
}

