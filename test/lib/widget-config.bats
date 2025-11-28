#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/tmux/tmux-ops.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/widget/widget-config.sh"
}

teardown() {
  cleanup_test_environment
}

@test "widget-config.sh - get_widget_option returns default when option not set" {
  export TMUX_SHOW_OPTION_VALUE=""
  result=$(get_widget_option "@test_option" "default")
  [[ "$result" == "default" ]]
}

@test "widget-config.sh - get_widget_option returns value when option is set" {
  export TMUX_SHOW_OPTION_VALUE="test_value"
  result=$(get_widget_option "@test_option" "default")
  [[ "$result" == "test_value" ]]
}

@test "widget-config.sh - is_widget_feature_enabled returns 1 when enabled" {
  export TMUX_SHOW_OPTION_VALUE="1"
  result=$(is_widget_feature_enabled "@test_option" "0")
  [[ "$result" == "1" ]]
}

@test "widget-config.sh - is_widget_feature_enabled returns 0 when disabled" {
  export TMUX_SHOW_OPTION_VALUE="0"
  result=$(is_widget_feature_enabled "@test_option" "1")
  [[ "$result" == "0" ]]
}

@test "widget-config.sh - is_widget_feature_enabled returns 1 for true" {
  export TMUX_SHOW_OPTION_VALUE="true"
  result=$(is_widget_feature_enabled "@test_option" "0")
  [[ "$result" == "1" ]]
}

@test "widget-config.sh - is_widget_feature_enabled returns 1 for yes" {
  export TMUX_SHOW_OPTION_VALUE="yes"
  result=$(is_widget_feature_enabled "@test_option" "0")
  [[ "$result" == "1" ]]
}

@test "widget-config.sh - get_widget_threshold returns default when option not set" {
  export TMUX_SHOW_OPTION_VALUE=""
  result=$(get_widget_threshold "@test_option" "50")
  [[ "$result" == "50" ]]
}

@test "widget-config.sh - get_widget_threshold returns value when option is set" {
  export TMUX_SHOW_OPTION_VALUE="75"
  result=$(get_widget_threshold "@test_option" "50")
  [[ "$result" == "75" ]]
}

