#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/coreutils-compat.sh"
}

teardown() {
  cleanup_test_environment
}

@test "coreutils-compat.sh - get_file_mtime returns 0 for file non-existent" {
  result=$(get_file_mtime "/file/non-existent")
  [[ "$result" == "0" ]]
}

@test "coreutils-compat.sh - get_file_mtime returns timestamp for file existente" {
  test_file="${TEST_TMPDIR}/test_file.txt"
  echo "test" > "$test_file"
  
  result=$(get_file_mtime "$test_file")
  [[ "$result" =~ ^[0-9]+$ ]]
  [[ "$result" != "0" ]]
}

@test "coreutils-compat.sh - get_current_timestamp returns timestamp valid" {
  result=$(get_current_timestamp)
  [[ "$result" =~ ^[0-9]+$ ]]
  [[ "$result" -gt 0 ]]
}

@test "coreutils-compat.sh - get_time_diff calculates difference correctly" {
  start_time=1000
  end_time=1500
  
  result=$(get_time_diff "$start_time" "$end_time")
  [[ "$result" == "500" ]]
}

@test "coreutils-compat.sh - get_time_diff uses timestamp atual when end not fornecido" {
  start_time=$(get_current_timestamp)
  sleep 1
  result=$(get_time_diff "$start_time")
  
  # should ser by menos 1 segundo
  [[ "$result" -ge 1 ]]
}

@test "coreutils-compat.sh - get_file_mtime works on macOS" {
  export MOCK_UNAME_S="Darwin"
  test_file="${TEST_TMPDIR}/test_file.txt"
  echo "test" > "$test_file"
  
  export MOCK_FILE_MTIME="1234567890"
  result=$(get_file_mtime "$test_file")
  [[ "$result" == "1234567890" ]]
}

@test "coreutils-compat.sh - get_file_mtime works on Linux" {
  export MOCK_UNAME_S="Linux"
  test_file="${TEST_TMPDIR}/test_file.txt"
  echo "test" > "$test_file"
  
  export MOCK_FILE_MTIME="1234567890"
  result=$(get_file_mtime "$test_file")
  [[ "$result" == "1234567890" ]]
}

