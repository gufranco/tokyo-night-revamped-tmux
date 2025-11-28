#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/coreutils-compat.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/cache.sh"
}

teardown() {
  cleanup_test_environment
}

@test "cache.sh - get_refresh_rate returns value default" {
  unset TMUX_REFRESH_RATE
  result=$(get_refresh_rate)
  [[ "$result" == "5" ]]
}

@test "cache.sh - get_refresh_rate returns tmux value" {
  export TMUX_REFRESH_RATE="10"
  result=$(get_refresh_rate)
  [[ "$result" == "10" ]]
}

@test "cache.sh - get_cache_file returns correct path" {
  result=$(get_cache_file "test_widget")
  [[ "$result" == "/tmp/tmux_tokyo_night_cache/test_widget.cache" ]]
}

@test "cache.sh - is_cache_valid returns false for file non-existent" {
  if ! is_cache_valid "/file/non-existent" "5"; then
    true
  else
    false
  fi
}

@test "cache.sh - is_cache_valid returns true for cache valid" {
  cache_file="${TEST_TMPDIR}/test.cache"
  current_time=$(get_current_timestamp)
  create_test_cache_file "$cache_file" "test content" "$current_time"

  if is_cache_valid "$cache_file" "900"; then
    true
  else
    false
  fi
}

@test "cache.sh - is_cache_valid returns false for cache expired" {
  cache_file="${TEST_TMPDIR}/test.cache"
  old_time=$(( $(get_current_timestamp) - 1000 ))
  echo "test content" > "$cache_file"
  export MOCK_FILE_MTIME="$old_time"

  if ! is_cache_valid "$cache_file" "100"; then
    true
  else
    false
  fi
}

@test "cache.sh - get_cached_value returns value when cache valid" {
  cache_file="${TEST_TMPDIR}/test_widget.cache"
  echo "cached value" > "$cache_file"
  current_time=$(get_current_timestamp)
  touch -d "@$current_time" "$cache_file" 2>/dev/null || true

  export CACHE_DIR="${TEST_TMPDIR}"

  # Create mock function for get_cache_file
  get_cache_file() {
    echo "${CACHE_DIR}/test_widget.cache"
  }

  export -f get_cache_file

  result=$(get_cached_value "test_widget" "900")
  [[ "$result" == "cached value" ]]
}

@test "cache.sh - get_cached_value returns error when cache invalid" {
  if ! get_cached_value "non-existent" "5" >/dev/null 2>&1; then
    true
  else
    false
  fi
}

@test "cache.sh - set_cached_value saves value in cache" {
  cache_file="${TEST_TMPDIR}/test_widget.cache"
  export CACHE_DIR="${TEST_TMPDIR}"

  set_cached_value "test_widget" "test value"

  [[ -f "$cache_file" ]]
  [[ "$(cat "$cache_file")" == "test value" ]]
}

@test "cache.sh - is_cache_valid works on macOS" {
  export MOCK_UNAME_S="Darwin"
  cache_file="${TEST_TMPDIR}/test.cache"
  export MOCK_FILE_MTIME=$(get_current_timestamp)
  echo "test" > "$cache_file"

  if is_cache_valid "$cache_file" "900"; then
    true
  else
    false
  fi
}

@test "cache.sh - is_cache_valid works on Linux" {
  export MOCK_UNAME_S="Linux"
  cache_file="${TEST_TMPDIR}/test.cache"
  export MOCK_FILE_MTIME=$(get_current_timestamp)
  echo "test" > "$cache_file"

  if is_cache_valid "$cache_file" "900"; then
    true
  else
    false
  fi
}

@test "cache.sh - is_cache_valid returns false for timestamp invalid" {
  cache_file="${TEST_TMPDIR}/test.cache"
  echo "test" > "$cache_file"
  export MOCK_FILE_MTIME="invalid"

  if ! is_cache_valid "$cache_file" "900"; then
    true
  else
    false
  fi
}

