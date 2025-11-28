#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/retry.sh"
}

teardown() {
  cleanup_test_environment
  rm -rf "${HOME}/.tmux/tokyo-night-breakers/" 2>/dev/null || true
}

@test "retry.sh - retry_command succeeds on first attempt" {
  run retry_command "true"
  [[ $status -eq 0 ]]
}

@test "retry.sh - retry_command fails after max attempts" {
  run retry_command "false" 3
  [[ $status -eq 1 ]]
}

@test "retry.sh - retry_with_backoff uses exponential backoff" {
  local start_time
  start_time=$(date +%s)
  
  retry_with_backoff "false" 3 1 5 2 || true
  
  local end_time
  end_time=$(date +%s)
  
  local elapsed=$((end_time - start_time))
  [[ $elapsed -ge 3 ]]
}

@test "retry.sh - retry_with_timeout respects timeout" {
  run retry_with_timeout "sleep 20" 1 1
  [[ $status -eq 1 ]]
}

@test "retry.sh - circuit_breaker_check allows when no failures" {
  run circuit_breaker_check "test_service" 5 300
  [[ $status -eq 0 ]]
}

@test "retry.sh - circuit_breaker_record_failure increments counter" {
  circuit_breaker_record_failure "test_service"
  
  local breaker_file="${HOME}/.tmux/tokyo-night-breakers/test_service.breaker"
  [[ -f "$breaker_file" ]]
  
  local count
  count=$(head -1 "$breaker_file")
  [[ "$count" == "1" ]]
}

@test "retry.sh - circuit_breaker opens after threshold" {
  for i in {1..5}; do
    circuit_breaker_record_failure "test_service"
  done
  
  run circuit_breaker_check "test_service" 5 300
  [[ $status -eq 1 ]]
}

@test "retry.sh - circuit_breaker_reset clears failures" {
  circuit_breaker_record_failure "test_service"
  circuit_breaker_reset "test_service"
  
  local breaker_file="${HOME}/.tmux/tokyo-night-breakers/test_service.breaker"
  [[ ! -f "$breaker_file" ]]
}

@test "retry.sh - sanitizes service names" {
  circuit_breaker_record_failure "test/../service"
  
  local breaker_file="${HOME}/.tmux/tokyo-night-breakers/testservice.breaker"
  [[ -f "$breaker_file" ]] || [[ -f "${HOME}/.tmux/tokyo-night-breakers/test..service.breaker" ]]
}

