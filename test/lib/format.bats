#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/format.sh"
}

teardown() {
  cleanup_test_environment
}

@test "format.sh - pad_percentage formats correctly" {
  result=$(pad_percentage "50")
  [[ "$result" == "50% " ]]
}

@test "format.sh - pad_percentage works with valores diferentes" {
  result1=$(pad_percentage "1")
  result2=$(pad_percentage "100")

  [[ -n "$result1" ]]
  [[ -n "$result2" ]]
  [[ "$result1" =~ % ]]
  [[ "$result2" =~ % ]]
}

@test "format.sh - pad_number formats with sufixo" {
  result=$(pad_number "100" "ms" "5")
  [[ "$result" == "100ms" ]]
}

@test "format.sh - pad_number uses default width when not specified" {
  result=$(pad_number "50" "ms")
  [[ -n "$result" ]]
  [[ "$result" =~ ms ]]
}

@test "format.sh - pad_number works without sufixo" {
  result=$(pad_number "100" "" "4")
  [[ "$result" == "100 " ]]
}

@test "format.sh - pad_speed formats speed" {
  result=$(pad_speed "1.5MB/s")
  [[ -n "$result" ]]
  [[ ${#result} -eq 8 ]]
}

@test "format.sh - pad_speed works with diferentes valores" {
  result1=$(pad_speed "100KB/s")
  result2=$(pad_speed "10.5MB/s")

  [[ -n "$result1" ]]
  [[ -n "$result2" ]]
  [[ ${#result1} -eq 8 ]]
  [[ ${#result2} -eq 8 ]]
}

