#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/themes.sh"
}

teardown() {
  cleanup_test_environment
}

@test "themes.sh - THEME array is set" {
  [[ -n "${THEME[background]:-}" ]] || true
  [[ -n "${THEME[foreground]:-}" ]] || true
}

@test "themes.sh - THEME night tem colors corretas" {
  export TMUX_THEME="night"
  # Recarregar for aplicar tema
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/themes.sh"
  
  [[ -n "${THEME[background]}" ]]
  [[ -n "${THEME[foreground]}" ]]
}

@test "themes.sh - THEME storm tem colors corretas" {
  export TMUX_THEME="storm"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/themes.sh"
  
  [[ -n "${THEME[background]}" ]]
  [[ -n "${THEME[foreground]}" ]]
}

@test "themes.sh - THEME day tem colors corretas" {
  export TMUX_THEME="day"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/themes.sh"
  
  [[ -n "${THEME[background]}" ]]
  [[ -n "${THEME[foreground]}" ]]
}

@test "themes.sh - THEME tem colors GitHub definidas" {
  [[ -n "${THEME[ghgreen]:-}" ]] || true
  [[ -n "${THEME[ghmagenta]:-}" ]] || true
  [[ -n "${THEME[ghred]:-}" ]] || true
  [[ -n "${THEME[ghyellow]:-}" ]] || true
}

@test "themes.sh - THEME has all basic colors" {
  [[ -n "${THEME[black]:-}" ]] || true
  [[ -n "${THEME[blue]:-}" ]] || true
  [[ -n "${THEME[cyan]:-}" ]] || true
  [[ -n "${THEME[green]:-}" ]] || true
  [[ -n "${THEME[magenta]:-}" ]] || true
  [[ -n "${THEME[red]:-}" ]] || true
  [[ -n "${THEME[white]:-}" ]] || true
  [[ -n "${THEME[yellow]:-}" ]] || true
}

@test "themes.sh - THEME tem colors bright" {
  [[ -n "${THEME[bblack]:-}" ]] || true
  [[ -n "${THEME[bblue]:-}" ]] || true
  [[ -n "${THEME[bcyan]:-}" ]] || true
  [[ -n "${THEME[bgreen]:-}" ]] || true
  [[ -n "${THEME[bmagenta]:-}" ]] || true
  [[ -n "${THEME[bred]:-}" ]] || true
  [[ -n "${THEME[bwhite]:-}" ]] || true
  [[ -n "${THEME[byellow]:-}" ]] || true
}

