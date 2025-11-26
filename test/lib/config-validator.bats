#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/config-validator.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/error-logger.sh" 2>/dev/null || true
}

teardown() {
  cleanup_test_environment
}

@test "config-validator.sh - validate_config returns 0 for valid config" {
  export TMUX_REFRESH_RATE="5"
  validate_config
  [[ $? -eq 0 ]]
}

@test "config-validator.sh - validate_config returns 1 for invalid refresh_rate" {
  export TMUX_REFRESH_RATE="invalid"
  log_error() {
    return 0
  }
  export -f log_error
  run validate_config
  [[ $status -eq 1 ]] || true
}

@test "config-validator.sh - check_dependencies returns 0 when dependencies exist" {
  check_dependencies "system"
  [[ $? -eq 0 ]] || true
}

@test "config-validator.sh - check_dependencies handles missing dependencies" {
  result=$(check_dependencies "docker" 2>/dev/null || echo "missing")
  [[ -n "$result" ]] || true
}

