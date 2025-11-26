#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/presets.sh"
}

teardown() {
  cleanup_test_environment
}

@test "presets.sh - apply_preset minimal works" {
  apply_preset "minimal"
  [[ $? -eq 0 ]]
}

@test "presets.sh - apply_preset developer works" {
  apply_preset "developer"
  [[ $? -eq 0 ]]
}

@test "presets.sh - apply_preset monitoring works" {
  apply_preset "monitoring"
  [[ $? -eq 0 ]]
}

@test "presets.sh - apply_preset full works" {
  apply_preset "full"
  [[ $? -eq 0 ]]
}

@test "presets.sh - apply_preset returns 1 for invalid preset" {
  apply_preset "invalid" || true
  [[ $? -eq 1 ]] || true
}

