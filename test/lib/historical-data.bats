#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/historical-data.sh"
  mkdir -p "${HOME}/.tmux/yoru-data" 2>/dev/null
}

teardown() {
  cleanup_test_environment
  rm -f "${HOME}/.tmux/yoru-data"/*.csv 2>/dev/null || true
}

@test "historical-data.sh - save_historical_point creates data file" {
  save_historical_point "test_metric" "50"
  [[ -f "${HOME}/.tmux/yoru-data/test_metric.csv" ]]
}

@test "historical-data.sh - get_historical_trend returns trend" {
  save_historical_point "test_metric" "10"
  save_historical_point "test_metric" "20"
  save_historical_point "test_metric" "30"
  result=$(get_historical_trend "test_metric")
  [[ -n "$result" ]]
}

@test "historical-data.sh - get_historical_average calculates average" {
  save_historical_point "test_metric" "10"
  save_historical_point "test_metric" "20"
  save_historical_point "test_metric" "30"
  result=$(get_historical_average "test_metric" 3)
  [[ -n "$result" ]]
}

