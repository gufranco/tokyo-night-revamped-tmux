#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/system.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/has-command.sh"
}

teardown() {
  cleanup_test_environment
}

@test "system.sh - safe_divide returns default when denominador é zero" {
  result=$(safe_divide "100" "0" "42")
  [[ "$result" == "42" ]]
}

@test "system.sh - safe_divide calculates correctly" {
  result=$(safe_divide "100" "2" "0")
  [[ "$result" == "50" ]]
}

@test "system.sh - safe_divide returns 0 when default not specified" {
  result=$(safe_divide "100" "0")
  [[ "$result" == "0" ]]
}

@test "system.sh - clamp_value returns min when value < min" {
  result=$(clamp_value "5" "10" "100")
  [[ "$result" == "10" ]]
}

@test "system.sh - clamp_value returns max when value > max" {
  result=$(clamp_value "150" "10" "100")
  [[ "$result" == "100" ]]
}

@test "system.sh - clamp_value returns value when dentro of limits" {
  result=$(clamp_value "50" "10" "100")
  [[ "$result" == "50" ]]
}

@test "system.sh - has_command returns true for command existente" {
  if has_command "echo"; then
    true
  else
    false
  fi
}

@test "system.sh - has_command returns false for command non-existent" {
  if ! has_command "command_inexistente_xyz123"; then
    true
  else
    false
  fi
}

