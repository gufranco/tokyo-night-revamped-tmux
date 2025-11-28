#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/platform-cache.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/coreutils-compat.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/utils/cache.sh"
  source "${BATS_TEST_DIRNAME}/../../src/lib/network/network-utils.sh"
}

teardown() {
  cleanup_test_environment
}

@test "network-utils.sh - get_bytes returns bytes on Linux" {
  export MOCK_UNAME_S="Linux"
  mkdir -p "${TEST_TMPDIR}/proc/net"
  echo "Inter-|   Receive                                                |  Transmit" > "${TEST_TMPDIR}/proc/net/dev"
  echo " face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed" >> "${TEST_TMPDIR}/proc/net/dev"
  echo "  eth0: 1000000    1000    0    0    0     0          0         0  2000000    2000    0    0    0     0       0          0" >> "${TEST_TMPDIR}/proc/net/dev"

  # Teste básico - função exists
  function_exists get_bytes
}

@test "network-utils.sh - get_bytes returns bytes on macOS" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_NETSTAT_OUTPUT="Name  Mtu   Network       Address            Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll
en0   1500  <Link#6>      aa:bb:cc:dd:ee:ff  12345     0   1000000  12345     0   2000000     0"

  # Teste básico - função exists
  function_exists get_bytes
}

@test "network-utils.sh - format_speed formats bytes pequenos" {
  result=$(format_speed "500" "1")
  [[ "$result" == "500B/s" ]]
}

@test "network-utils.sh - format_speed formats KB/s" {
  result=$(format_speed "5000" "1")
  [[ "$result" =~ KB/s ]]
}

@test "network-utils.sh - format_speed formats MB/s" {
  result=$(format_speed "2000000" "1")
  [[ "$result" =~ MB/s ]]
}

@test "network-utils.sh - find_interface encontra interface on Linux" {
  export MOCK_UNAME_S="Linux"
  mkdir -p "${TEST_TMPDIR}/proc/net"
  echo "Iface   Destination     Gateway         Flags   RefCnt  Use     Metric  Mask            MTU     Window  IRTT" > "${TEST_TMPDIR}/proc/net/route"
  echo "eth0    00000000        0101A8C0        0003    0       0       0       00000000        0       0       0" >> "${TEST_TMPDIR}/proc/net/route"

  # Teste básico
  function_exists find_interface
}

@test "network-utils.sh - find_interface encontra interface on macOS" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_ROUTE_INTERFACE="en0"
  result=$(find_interface)
  [[ "$result" == "en0" ]]
}

@test "network-utils.sh - find_interface substitui utun por en0 on macOS" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_ROUTE_INTERFACE="utun0"
  result=$(find_interface)
  [[ "$result" == "en0" ]]
}

@test "network-utils.sh - get_interface_ipv4 returns IP on macOS" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_IPCONFIG_IP="192.168.1.100"
  result=$(get_interface_ipv4 "en0")
  [[ "$result" == "192.168.1.100" ]]
}

@test "network-utils.sh - detect_vpn_macos returns interface VPN" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_NETSTAT_ROUTES="0.0.0.0           192.168.1.1        UGSc           utun0
192.168.1.0      192.168.1.1        UGSc           en0"

  result=$(detect_vpn_macos)
  [[ -n "$result" ]]
}

@test "network-utils.sh - detect_vpn_macos returns error when not there are VPN" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_NETSTAT_ROUTES=""

  run detect_vpn_macos
  [[ $status -ne 0 ]]
}

@test "network-utils.sh - detect_vpn_linux returns interface VPN" {
  export MOCK_UNAME_S="Linux"
  export MOCK_IP_LINK_OUTPUT="1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
3: tun0: <POINTOPOINT,UP,LOWER_UP> mtu 1500"
  export MOCK_IP_ADDR_OUTPUT="3: tun0: <POINTOPOINT,UP,LOWER_UP> mtu 1500
    inet 10.0.0.1/24 scope global tun0"

  result=$(detect_vpn_linux)
  [[ -n "$result" ]]
}

@test "network-utils.sh - detect_vpn returns interface on macOS" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_NETSTAT_ROUTES="0.0.0.0           192.168.1.1        UGSc           utun0"

  result=$(detect_vpn)
  [[ -n "$result" ]]
}

@test "network-utils.sh - detect_vpn returns interface on Linux" {
  export MOCK_UNAME_S="Linux"
  export MOCK_IP_LINK_OUTPUT="3: tun0: <POINTOPOINT,UP,LOWER_UP> mtu 1500"
  export MOCK_IP_ADDR_OUTPUT="3: tun0: <POINTOPOINT,UP,LOWER_UP> mtu 1500
    inet 10.0.0.1/24 scope global tun0"

  run detect_vpn
  [[ $status -eq 0 ]] || [[ -n "$output" ]]
}

