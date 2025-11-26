#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/system.sh"
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

@test "system.sh - command_exists returns true for command existente" {
  run command_exists "echo"
  [[ $status -eq 0 ]]
}

@test "system.sh - command_exists returns false for command non-existent" {
  run command_exists "command_inexistente_xyz123"
  [[ $status -ne 0 ]]
}

@test "system.sh - require_command returns true for command existente" {
  run require_command "echo"
  [[ $status -eq 0 ]]
}

@test "system.sh - require_command returns false for command non-existent" {
  run require_command "command_inexistente_xyz123"
  [[ $status -ne 0 ]]
}

@test "system.sh - check_required_command returns true for command existente" {
  run check_required_command "echo" "install message"
  [[ $status -eq 0 ]]
}

@test "system.sh - check_required_command returns false e mensagem for command non-existent" {
  run check_required_command "command_inexistente_xyz123" "install message"
  [[ $status -ne 0 ]]
  [[ "$output" =~ install ]]
}

@test "system.sh - check_any_command returns true when primeiro exists" {
  run check_any_command "echo" "command_inexistente"
  [[ $status -eq 0 ]]
}

@test "system.sh - check_any_command returns true when segundo exists" {
  run check_any_command "command_inexistente" "echo"
  [[ $status -eq 0 ]]
}

@test "system.sh - check_any_command returns false when nenhum exists" {
  run check_any_command "command_inexistente1" "command_inexistente2"
  [[ $status -ne 0 ]]
}

