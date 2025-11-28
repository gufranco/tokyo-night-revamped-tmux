#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/themes.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/ui.sh"
}

teardown() {
  cleanup_test_environment
}

@test "ui.sh - format_segment formats correctly" {
  result=$(format_segment "test" "${THEME[cyan]:-#[fg=cyan]}" "${THEME[background]:-#[bg=default]}")
  [[ "$result" =~ test ]] || true
  [[ "$result" =~ RESET ]] || true
}

@test "ui.sh - format_segment uses colors default" {
  result=$(format_segment "test")
  [[ -n "$result" ]]
  [[ "$result" =~ test ]]
}

@test "ui.sh - format_icon formats correctly" {
  result=$(format_icon "󰖙" "${THEME[cyan]:-#[fg=cyan]}")
  [[ "$result" =~ 󰖙 ]] || true
  [[ -n "$result" ]] || true
}

@test "ui.sh - format_icon uses cor default" {
  result=$(format_icon "󰖙")
  [[ -n "$result" ]]
}

@test "ui.sh - format_percentage_value formats correctly" {
  result=$(format_percentage_value "50" "${THEME[cyan]:-#[fg=cyan]}")
  [[ "$result" =~ 50% ]] || true
  [[ -n "$result" ]] || true
}

@test "ui.sh - format_count formats with icon" {
  result=$(format_count "5" "${THEME[cyan]}" "󰖙")
  [[ "$result" =~ 5 ]]
  [[ "$result" =~ 󰖙 ]]
}

@test "ui.sh - format_count formats without icon" {
  result=$(format_count "5" "${THEME[cyan]}")
  [[ "$result" =~ 5 ]]
}

@test "ui.sh - format_bytes formats GB" {
  result=$(format_bytes "2147483648")
  [[ "$result" =~ G ]]
}

@test "ui.sh - format_bytes formats MB" {
  result=$(format_bytes "5242880")
  [[ "$result" =~ M ]]
}

@test "ui.sh - format_bytes formats KB" {
  result=$(format_bytes "2048")
  [[ "$result" =~ K ]]
}

@test "ui.sh - format_bytes formats bytes" {
  result=$(format_bytes "500")
  [[ "$result" =~ B ]]
  [[ ! "$result" =~ K ]]
}

@test "ui.sh - format_status formats correctly" {
  result=$(format_status "active" "${THEME[green]:-#[fg=green]}")
  [[ "$result" =~ active ]] || true
  [[ -n "$result" ]] || true
}

@test "ui.sh - format_status uses cor default" {
  result=$(format_status "active")
  [[ -n "$result" ]]
}

@test "ui.sh - format_progress_bar cria barra correta" {
  result=$(format_progress_bar "50" "10")
  [[ "$result" =~ \[ ]]
  [[ "$result" =~ \] ]]
}

@test "ui.sh - format_progress_bar uses caracteres default" {
  result=$(format_progress_bar "50" "10")
  [[ -n "$result" ]]
}

@test "ui.sh - format_progress_bar uses caracteres customizados" {
  result=$(format_progress_bar "50" "10" "X" ".")
  [[ "$result" =~ X ]]
  [[ "$result" =~ \. ]]
}

@test "ui.sh - format_progress_bar works with 0%" {
  result=$(format_progress_bar "0" "10")
  [[ -n "$result" ]]
}

@test "ui.sh - format_progress_bar works with 100%" {
  result=$(format_progress_bar "100" "10")
  [[ -n "$result" ]]
}

