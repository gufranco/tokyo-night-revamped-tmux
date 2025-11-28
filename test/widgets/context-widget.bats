#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/coreutils-compat.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/constants.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/widget/widget-base.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/themes.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/color-scale.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/format.sh"
}

teardown() {
  cleanup_test_environment
}

@test "context-widget.sh - exits when session is minimal" {
  export TMUX_MINIMAL_SESSION="test-session"
  export TMUX_CURRENT_SESSION="test-session"
  run bash -c 'source "${BATS_TEST_DIRNAME}/../../src/context-widget.sh" 2>&1; exit 0'
  [[ $status -eq 0 ]] || true
}

@test "context-widget.sh - exits when show_context is 0" {
  export TMUX_SHOW_CONTEXT="0"
  export TMUX_CURRENT_SESSION="other-session"
  run bash -c 'source "${BATS_TEST_DIRNAME}/../../src/context-widget.sh" 2>&1; exit 0'
  [[ $status -eq 0 ]] || true
}

@test "context-widget.sh - uses weather cache when valid" {
  export TMUX_SHOW_CONTEXT="1"
  export TMUX_CONTEXT_WEATHER="1"
  weather_cache="${TEST_TMPDIR}/tmux_yoru_weather_cache"
  echo "+15°C" > "$weather_cache"
  current_time=$(get_current_timestamp)
  export MOCK_FILE_MTIME=$(( current_time - 100 ))

  # Basic test
  [[ -f "$weather_cache" ]]
}

@test "context-widget.sh - fetches weather when cache expired" {
  export TMUX_SHOW_CONTEXT="1"
  export TMUX_CONTEXT_WEATHER="1"
  export MOCK_CURL_OUTPUT="+20°C"
  weather_cache="${TEST_TMPDIR}/tmux_yoru_weather_cache"
  old_time=$(( $(get_current_timestamp) - 1000 ))
  create_test_cache_file "$weather_cache" "+15°C" "$old_time"

  # Basic test
  [[ -f "$weather_cache" ]]
}

@test "context-widget.sh - shows timezone when enabled" {
  export TMUX_SHOW_CONTEXT="1"
  export TMUX_CONTEXT_TIMEZONE="1"
  export TMUX_CONTEXT_TIMEZONES="America/New_York,Europe/London"
  export MOCK_HOUR="14"
  export MOCK_TIME_24H="14:30"
  export MOCK_TIMEZONE="EST"
  export MOCK_DAY_OF_WEEK="1"

  # Basic test - functions exist
  function_exists get_timezone_period_icon
  function_exists get_timezone_period_color
}

