#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/error-logger.sh"
  mkdir -p "${HOME}/.tmux/tokyo-night-logs" 2>/dev/null
}

teardown() {
  cleanup_test_environment
  rm -f "${HOME}/.tmux/tokyo-night-logs"/*.log 2>/dev/null || true
}

@test "error-logger.sh - log_error writes to log file when enabled" {
  export TMUX_ENABLE_LOGGING="1"
  log_error "test_widget" "Test error message"
  [[ -f "${HOME}/.tmux/tokyo-night-logs/errors.log" ]]
  grep -q "Test error message" "${HOME}/.tmux/tokyo-night-logs/errors.log" || true
}

@test "error-logger.sh - log_error does not write when disabled" {
  export TMUX_ENABLE_LOGGING="0"
  rm -f "${HOME}/.tmux/tokyo-night-logs/errors.log" 2>/dev/null || true
  log_error "test_widget" "Test error message"
  [[ ! -f "${HOME}/.tmux/tokyo-night-logs/errors.log" ]] || true
}

@test "error-logger.sh - log_performance writes to log file when enabled" {
  export TMUX_ENABLE_PROFILING="1"
  log_performance "test_widget" "100"
  [[ -f "${HOME}/.tmux/tokyo-night-logs/performance.log" ]]
  grep -q "test_widget" "${HOME}/.tmux/tokyo-night-logs/performance.log" || true
}

@test "error-logger.sh - log_performance does not write when disabled" {
  export TMUX_ENABLE_PROFILING="0"
  rm -f "${HOME}/.tmux/tokyo-night-logs/performance.log" 2>/dev/null || true
  log_performance "test_widget" "100"
  [[ ! -f "${HOME}/.tmux/tokyo-night-logs/performance.log" ]] || true
}

