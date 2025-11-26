#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/widget-loader.sh"
}

teardown() {
  cleanup_test_environment
}

@test "widget-loader.sh - load_core_libs loads core libraries" {
  run load_core_libs
  [[ $status -eq 0 ]]
}

@test "widget-loader.sh - load_widget_base loads widget base libraries" {
  run load_widget_base
  [[ $status -eq 0 ]]
}

@test "widget-loader.sh - load_platform_libs loads platform libraries" {
  run load_platform_libs
  [[ $status -eq 0 ]]
}

@test "widget-loader.sh - load_optional_libs loads optional libraries" {
  run load_optional_libs
  [[ $status -eq 0 ]]
}

@test "widget-loader.sh - load_widget_dependencies loads system dependencies" {
  run load_widget_dependencies "system"
  [[ $status -eq 0 ]]
}

@test "widget-loader.sh - load_widget_dependencies loads git dependencies" {
  run load_widget_dependencies "git"
  [[ $status -eq 0 ]]
}

@test "widget-loader.sh - load_widget_dependencies loads network dependencies" {
  run load_widget_dependencies "network"
  [[ $status -eq 0 ]]
}

@test "widget-loader.sh - load_widget_dependencies loads context dependencies" {
  run load_widget_dependencies "context"
  [[ $status -eq 0 ]]
}

@test "widget-loader.sh - load_widget_dependencies loads default dependencies" {
  run load_widget_dependencies "unknown"
  [[ $status -eq 0 ]]
}

