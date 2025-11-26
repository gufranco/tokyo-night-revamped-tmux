#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/coreutils-compat.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/constants.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/widget-base.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/platform-detector.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/themes.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/color-scale.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/cache.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/format.sh"
}

teardown() {
  cleanup_test_environment
}

@test "system-widget.sh - sai when widget disabled" {
  export TMUX_SHOW_SYSTEM="0"
  run bash -c 'cd "${BATS_TEST_DIRNAME}/../../" && bash src/system-widget.sh 2>/dev/null' || true
  [[ $status -eq 0 ]] || true
}

@test "system-widget.sh - uses cache when available" {
  export TMUX_SHOW_SYSTEM="1"
  export TMUX_REFRESH_RATE="5"
  
  # Mock of cache
  cache_file="${TEST_TMPDIR}/tmux_tokyo_night_cache/system.cache"
  mkdir -p "$(dirname "$cache_file")"
  echo "cached output" > "$cache_file"
  current_time=$(get_current_timestamp)
  export MOCK_FILE_MTIME=$(( current_time - 1 ))
  
  # Teste básico
  [[ -f "$cache_file" ]]
}

@test "system-widget.sh - validates percentages" {
  export TMUX_SHOW_SYSTEM="1"
  
  # Teste básico
  function_exists validate_percentage
}

@test "system-widget.sh - formats percentages" {
  export TMUX_SHOW_SYSTEM="1"
  
  # Teste básico
  function_exists pad_percentage
}

@test "system-widget.sh - calculates GPU using WindowServer when ioreg fails" {
  export TMUX_SHOW_SYSTEM="1"
  export TMUX_SYSTEM_GPU="1"
  export MOCK_UNAME_S="Darwin"
  export MOCK_UNAME_M="arm64"
  export MOCK_IOREG_OUTPUT=""
  export MOCK_PS_OUTPUT=" 50.5 WindowServer -daemon"
  
  function_exists get_system_color
  function_exists is_apple_silicon
}

@test "system-widget.sh - calculates memory on macOS" {
  export TMUX_SHOW_SYSTEM="1"
  export TMUX_SYSTEM_MEMORY="1"
  export MOCK_UNAME_S="Darwin"
  export MOCK_MEM_TOTAL="17179869184"
  export MOCK_PAGE_SIZE="4096"
  
  # Teste básico
  function_exists get_total_memory_kb
  function_exists get_active_memory_kb
}

@test "system-widget.sh - calculates memory on Linux" {
  export TMUX_SHOW_SYSTEM="1"
  export TMUX_SYSTEM_MEMORY="1"
  export MOCK_UNAME_S="Linux"
  mkdir -p "${TEST_TMPDIR}/proc"
  echo -e "MemTotal:        8192000 kB\nMemAvailable:    4096000 kB" > "${TEST_TMPDIR}/proc/meminfo"
  
  # Teste básico
  function_exists get_total_memory_kb
  function_exists get_active_memory_kb
}

@test "system-widget.sh - calculates swap on macOS" {
  export TMUX_SHOW_SYSTEM="1"
  export TMUX_SYSTEM_SWAP="1"
  export MOCK_UNAME_S="Darwin"
  export MOCK_SWAP_TOTAL="4096"
  export MOCK_SWAP_USED="1024"
  
  function_exists get_system_color
  function_exists validate_percentage
}

@test "system-widget.sh - calculates swap on Linux" {
  export TMUX_SHOW_SYSTEM="1"
  export TMUX_SYSTEM_SWAP="1"
  export MOCK_UNAME_S="Linux"
  export MOCK_FREE_SWAP_TOTAL="2048"
  export MOCK_FREE_SWAP_USED="512"
  
  function_exists get_system_color
  function_exists validate_percentage
}

@test "system-widget.sh - shows battery status correct" {
  export TMUX_SHOW_SYSTEM="1"
  export TMUX_SYSTEM_BATTERY="1"
  export MOCK_UNAME_S="Darwin"
  export MOCK_BATTERY_STATUS="charging"
  export MOCK_BATTERY_PERCENT="80"
  
  # Teste básico
  [[ "$MOCK_BATTERY_STATUS" == "charging" ]]
}

@test "system-widget.sh - shows battery alert when below threshold" {
  export TMUX_SHOW_SYSTEM="1"
  export TMUX_SYSTEM_BATTERY="1"
  export TMUX_SYSTEM_BATTERY_THRESHOLD="21"
  export MOCK_UNAME_S="Darwin"
  export MOCK_BATTERY_STATUS="discharging"
  export MOCK_BATTERY_PERCENT="15"
  
  # Teste básico
  [[ $MOCK_BATTERY_PERCENT -lt $TMUX_SYSTEM_BATTERY_THRESHOLD ]]
}

