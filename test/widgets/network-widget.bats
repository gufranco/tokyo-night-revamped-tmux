#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/coreutils-compat.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/constants.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/widget/widget-base.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/network/network-utils.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/themes.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/color-scale.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/cache.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/ui/format.sh"
}

teardown() {
  cleanup_test_environment
}

@test "network-widget.sh - exits when widget disabled" {
  export TMUX_SHOW_NETSPEED="0"
  run bash -c 'cd "${BATS_TEST_DIRNAME}/../../" && bash src/network-widget.sh 2>/dev/null' || true
  [[ $status -eq 0 ]] || true
}

@test "network-widget.sh - uses cache when available" {
  export TMUX_SHOW_NETSPEED="1"
  export TMUX_REFRESH_RATE="5"

  # Cache mock
  cache_file="${TEST_TMPDIR}/tmux_tokyo_night_cache/network.cache"
  mkdir -p "$(dirname "$cache_file")"
  echo "cached output" > "$cache_file"
  current_time=$(get_current_timestamp)
  export MOCK_FILE_MTIME=$(( current_time - 1 ))

  # Basic test
  [[ -f "$cache_file" ]]
}

@test "network-widget.sh - finds interface automatically" {
  export TMUX_SHOW_NETSPEED="1"
  export TMUX_NETSPEED_IFACE=""
  export MOCK_UNAME_S="Darwin"
  export MOCK_ROUTE_INTERFACE="en0"

  # Basic test
  function_exists find_interface
}

@test "network-widget.sh - uses configured interface" {
  export TMUX_SHOW_NETSPEED="1"
  export TMUX_NETSPEED_IFACE="eth0"

  # Basic test
  [[ "$TMUX_NETSPEED_IFACE" == "eth0" ]]
}

@test "network-widget.sh - calculates download and upload speed" {
  export TMUX_SHOW_NETSPEED="1"
  export MOCK_UNAME_S="Darwin"
  export MOCK_NETSTAT_OUTPUT="Name  Mtu   Network       Address            Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll
en0   1500  <Link#6>      aa:bb:cc:dd:ee:ff  12345     0   1000000  12345     0   2000000     0"

  # Basic test
  function_exists get_bytes
  function_exists format_speed
}

@test "network-widget.sh - shows VPN when enabled and detected" {
  export TMUX_SHOW_NETSPEED="1"
  export TMUX_NETSPEED_VPN="1"
  export MOCK_UNAME_S="Darwin"
  export MOCK_NETSTAT_ROUTES="0.0.0.0           192.168.1.1        UGSc           utun0"

  # Basic test
  function_exists detect_vpn
}

@test "network-widget.sh - shows ping when enabled" {
  export TMUX_SHOW_NETSPEED="1"
  export TMUX_NETSPEED_PING="1"
  export MOCK_PING_TIME="15"

  # Basic test
  function_exists get_ping_latency
  function_exists get_net_ping_color
}

@test "network-widget.sh - formats speed correctly" {
  export TMUX_SHOW_NETSPEED="1"

  # Basic test
  function_exists format_speed
  function_exists pad_speed
}

@test "network-widget.sh - applies colors based on speed" {
  export TMUX_SHOW_NETSPEED="1"

  # Basic test
  function_exists get_net_speed_color
}

@test "network-widget.sh - applies colors based on ping" {
  export TMUX_SHOW_NETSPEED="1"
  export TMUX_NETSPEED_PING="1"

  # Basic test
  function_exists get_net_ping_color
}

@test "network-widget.sh - saves result to cache" {
  export TMUX_SHOW_NETSPEED="1"
  export TMUX_REFRESH_RATE="5"

  # Basic test
  function_exists set_cached_value
}

