#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/platform-cache.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/widget/widget-base.sh"
}

teardown() {
  cleanup_test_environment
}

@test "widget-base.sh - validate_percentage returns 1 for value invalid" {
  result=$(validate_percentage "abc")
  [[ "$result" == "1" ]]
}

@test "widget-base.sh - validate_percentage returns 1 for value zero" {
  result=$(validate_percentage "0")
  [[ "$result" == "1" ]]
}

@test "widget-base.sh - validate_percentage returns 1 for value negativo" {
  result=$(validate_percentage "-10")
  [[ "$result" == "1" ]]
}

@test "widget-base.sh - validate_percentage returns 100 for value acima of 100" {
  result=$(validate_percentage "150")
  [[ "$result" == "100" ]]
}

@test "widget-base.sh - validate_percentage returns value original for value valid" {
  result=$(validate_percentage "50")
  [[ "$result" == "50" ]]
}

@test "widget-base.sh - validate_percentage returns 1 for value exatamente 1" {
  result=$(validate_percentage "1")
  [[ "$result" == "1" ]]
}

@test "widget-base.sh - validate_percentage returns 100 for value exatamente 100" {
  result=$(validate_percentage "100")
  [[ "$result" == "100" ]]
}

@test "widget-base.sh - validate_number returns value when valid" {
  result=$(validate_number "123" "0")
  [[ "$result" == "123" ]]
}

@test "widget-base.sh - validate_number returns default for value invalid" {
  result=$(validate_number "abc" "42")
  [[ "$result" == "42" ]]
}

@test "widget-base.sh - validate_number returns 0 when default not specified" {
  result=$(validate_number "abc")
  [[ "$result" == "0" ]]
}

@test "widget-base.sh - is_macos returns true on macOS" {
  export MOCK_UNAME_S="Darwin"
  if is_macos; then
    true
  else
    false
  fi
}

@test "widget-base.sh - is_macos returns false on Linux" {
  export MOCK_UNAME_S="Linux"
  if ! is_macos; then
    true
  else
    false
  fi
}

@test "widget-base.sh - is_linux returns true on Linux" {
  export MOCK_UNAME_S="Linux"
  if is_linux; then
    true
  else
    false
  fi
}

@test "widget-base.sh - is_linux returns false on macOS" {
  export MOCK_UNAME_S="Darwin"
  if ! is_linux; then
    true
  else
    false
  fi
}

@test "widget-base.sh - is_apple_silicon returns true on Apple Silicon" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_UNAME_M="arm64"
  if is_apple_silicon; then
    true
  else
    false
  fi
}

@test "widget-base.sh - is_apple_silicon returns false on Intel" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_UNAME_M="x86_64"
  if ! is_apple_silicon; then
    true
  else
    false
  fi
}

@test "widget-base.sh - is_apple_silicon returns false on Linux" {
  export MOCK_UNAME_S="Linux"
  export MOCK_UNAME_M="x86_64"
  if ! is_apple_silicon; then
    true
  else
    false
  fi
}

@test "widget-base.sh - is_widget_enabled returns true when enabled" {
  export TMUX_SHOW_SYSTEM="1"
  if is_widget_enabled "@tokyo-night-tmux_show_system"; then
    true
  else
    false
  fi
}

@test "widget-base.sh - is_widget_enabled returns false when disabled" {
  export TMUX_SHOW_SYSTEM="0"
  if ! is_widget_enabled "@tokyo-night-tmux_show_system"; then
    true
  else
    false
  fi
}
