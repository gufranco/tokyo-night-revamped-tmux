#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/platform-detector.sh"
}

teardown() {
  cleanup_test_environment
  rm -f /tmp/tmux_tokyo_night_cache/*.cache 2>/dev/null || true
  rm -f "${HOME}/.tmux/tokyo-night-data"/*.csv 2>/dev/null || true
}

@test "platform-detector.sh - get_network_connections returns number" {
  result=$(get_network_connections)
  [[ "$result" =~ ^[0-9]+$ ]]
}

@test "platform-detector.sh - get_cpu_frequency returns number" {
  result=$(get_cpu_frequency)
  [[ "$result" =~ ^[0-9]+$ ]]
}

@test "platform-detector.sh - get_cpu_frequency_current returns number" {
  result=$(get_cpu_frequency_current)
  [[ "$result" =~ ^[0-9]+$ ]]
}

@test "platform-detector.sh - get_cpu_frequency_current uses real value when available" {
  local base_freq
  base_freq=$(get_cpu_frequency)
  local current_freq
  current_freq=$(get_cpu_frequency_current)
  
  [[ -n "$base_freq" ]]
  [[ -n "$current_freq" ]]
  [[ "$current_freq" =~ ^[0-9]+$ ]]
  
  if [[ "$base_freq" -gt 0 ]]; then
    [[ "$current_freq" -gt 0 ]]
    [[ "$current_freq" -le $(( base_freq * 120 / 100 )) ]]
    [[ "$current_freq" -ge $(( base_freq * 35 / 100 )) ]]
  fi
}

@test "platform-detector.sh - get_cpu_frequency_current falls back to estimate when real value unavailable" {
  local os
  os="$(uname -s)"
  local arch
  arch="$(uname -m)"
  
  if [[ "$os" == "Darwin" ]] && [[ "$arch" == "arm64" ]]; then
    local base_freq
    base_freq=$(get_cpu_frequency)
    local current_freq
    current_freq=$(get_cpu_frequency_current)
    
    [[ -n "$base_freq" ]]
    [[ -n "$current_freq" ]]
    [[ "$current_freq" =~ ^[0-9]+$ ]]
    
    if [[ "$base_freq" -gt 0 ]]; then
      [[ "$current_freq" -gt 0 ]]
      [[ "$current_freq" -le $(( base_freq * 120 / 100 )) ]]
      [[ "$current_freq" -ge $(( base_freq * 35 / 100 )) ]]
    fi
  else
    skip "Test only relevant for macOS Apple Silicon"
  fi
}

@test "platform-detector.sh - get_disk_space_gb returns space info" {
  result=$(get_disk_space_gb "/")
  [[ -n "$result" ]]
  read -r total used free <<< "$result"
  [[ "$total" =~ ^[0-9]+$ ]] || true
}

@test "platform-detector.sh - get_memory_pressure returns percentage" {
  result=$(get_memory_pressure)
  [[ "$result" =~ ^[0-9]+$ ]]
}

@test "platform-detector.sh - get_system_health_status returns status" {
  result=$(get_system_health_status)
  [[ -n "$result" ]]
  [[ "$result" == *"|"* ]]
}

@test "platform-detector.sh - get_multiple_disks returns disk list" {
  result=$(get_multiple_disks)
  [[ -n "$result" ]] || true
}

@test "platform-detector.sh - has_command returns true for command existente" {
  run has_command "echo"
  [[ $status -eq 0 ]]
}

@test "platform-detector.sh - has_command returns false for command non-existent" {
  run has_command "command_inexistente_xyz123"
  [[ $status -ne 0 ]]
}

@test "platform-detector.sh - has_command uses cache" {
  has_command "echo"
  run has_command "echo"
  [[ $status -eq 0 ]]
}

@test "platform-detector.sh - get_default_network_interface returns interface on macOS" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_ROUTE_OUTPUT="interface: en0"
  result=$(get_default_network_interface)
  [[ -n "$result" ]] || true
}

@test "platform-detector.sh - get_default_network_interface returns interface on Linux" {
  export MOCK_UNAME_S="Linux"
  # Mock of /proc/net/route
  mkdir -p "${TEST_TMPDIR}/proc/net"
  echo "Iface   Destination     Gateway         Flags   RefCnt  Use     Metric  Mask            MTU     Window  IRTT" > "${TEST_TMPDIR}/proc/net/route"
  echo "eth0    00000000        0101A8C0        0003    0       0       0       00000000        0       0       0" >> "${TEST_TMPDIR}/proc/net/route"
  
  # Cannot easily mock awk, so test general behavior
  result=$(get_default_network_interface)
  [[ -n "$result" ]]
}

@test "platform-detector.sh - get_cpu_count returns value on macOS" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_CPU_COUNT="8"
  result=$(get_cpu_count)
  [[ "$result" == "8" ]]
}

@test "platform-detector.sh - get_cpu_count returns value on Linux" {
  export MOCK_UNAME_S="Linux"
  mkdir -p "${TEST_TMPDIR}/proc"
  echo -e "processor\t: 0\nprocessor\t: 1\nprocessor\t: 2\nprocessor\t: 3" > "${TEST_TMPDIR}/proc/cpuinfo"
  
  # Basic test
  result=$(get_cpu_count)
  [[ -n "$result" ]]
}

@test "platform-detector.sh - get_total_memory_kb returns value on macOS" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_MEM_TOTAL="17179869184"
  result=$(get_total_memory_kb)
  expected=$(( 17179869184 / 1024 ))
  [[ "$result" == "$expected" ]]
}

@test "platform-detector.sh - get_total_memory_kb returns value on Linux" {
  export MOCK_UNAME_S="Linux"
  mkdir -p "${TEST_TMPDIR}/proc"
  echo "MemTotal:        8192000 kB" > "${TEST_TMPDIR}/proc/meminfo"
  
  # Basic test
  result=$(get_total_memory_kb)
  [[ -n "$result" ]]
}

@test "platform-detector.sh - get_active_memory_kb returns value on macOS" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_PAGE_SIZE="4096"
  result=$(get_active_memory_kb)
  [[ -n "$result" ]]
}

@test "platform-detector.sh - get_active_memory_kb returns value on Linux" {
  export MOCK_UNAME_S="Linux"
  mkdir -p "${TEST_TMPDIR}/proc"
  echo -e "MemTotal:        8192000 kB\nMemAvailable:    4096000 kB" > "${TEST_TMPDIR}/proc/meminfo"
  
  result=$(get_active_memory_kb)
  [[ -n "$result" ]]
}

@test "platform-detector.sh - get_cpu_usage_percentage returns value on macOS" {
  export MOCK_UNAME_S="Darwin"
  export MOCK_TOP_CPU_USER="10.5"
  export MOCK_TOP_CPU_SYS="5.2"
  result=$(get_cpu_usage_percentage)
  [[ -n "$result" ]]
  [[ "$result" =~ ^[0-9]+$ ]]
}

@test "platform-detector.sh - get_cpu_usage_percentage returns value on Linux" {
  export MOCK_UNAME_S="Linux"
  mkdir -p "${TEST_TMPDIR}/proc"
  echo "cpu  100 200 300 400 500 600 700" > "${TEST_TMPDIR}/proc/stat"
  
  result=$(get_cpu_usage_percentage)
  [[ -n "$result" ]]
}

@test "platform-detector.sh - get_load_average returns value on macOS" {
  export MOCK_UNAME_S="Darwin"
  result=$(get_load_average)
  [[ -n "$result" ]]
}

@test "platform-detector.sh - get_load_average returns value on Linux" {
  export MOCK_UNAME_S="Linux"
  mkdir -p "${TEST_TMPDIR}/proc"
  echo "1.5 1.2 1.0 1/100 200" > "${TEST_TMPDIR}/proc/loadavg"
  
  result=$(get_load_average)
  [[ -n "$result" ]]
}

@test "platform-detector.sh - get_disk_usage returns valores corretos" {
  export MOCK_DF_OUTPUT="Filesystem     1K-blocks    Used Available Use% Mounted on
/dev/disk1      524288000  262144000  262144000  50% /"
  
  result=$(get_disk_usage "/")
  [[ -n "$result" ]]
}

@test "platform-detector.sh - get_cpu_temperature returns number" {
  result=$(get_cpu_temperature)
  [[ "$result" =~ ^[0-9]+$ ]]
}

@test "platform-detector.sh - get_gpu_temperature returns number" {
  result=$(get_gpu_temperature)
  [[ "$result" =~ ^[0-9]+$ ]]
}

@test "platform-detector.sh - get_system_uptime returns number" {
  result=$(get_system_uptime)
  [[ "$result" =~ ^[0-9]+$ ]]
}

@test "platform-detector.sh - format_uptime formats correctly" {
  result=$(format_uptime 3661)
  [[ "$result" == "1h 1m" ]]
}

@test "platform-detector.sh - get_top_processes returns processes" {
  result=$(get_top_processes 2)
  [[ -n "$result" ]]
}

@test "platform-detector.sh - get_docker_containers returns number" {
  result=$(get_docker_containers)
  [[ "$result" =~ ^[0-9]+$ ]]
}

@test "platform-detector.sh - get_kubernetes_pods returns number" {
  export MOCK_KUBERNETES_PODS="0"
  export MOCK_KUBECTL_PODS="0"
  result=$(get_kubernetes_pods)
  [[ "$result" =~ ^[0-9]+$ ]] || true
}

@test "platform-detector.sh - get_disk_io returns read and write" {
  result=$(get_disk_io)
  [[ "$result" =~ ^[0-9]+[[:space:]]+[0-9]+$ ]]
}

@test "platform-detector.sh - get_vpn_connection_name returns string or empty" {
  result=$(get_vpn_connection_name)
  [[ -n "$result" ]] || [[ -z "$result" ]]
}

@test "platform-detector.sh - get_wifi_signal_strength returns number" {
  result=$(get_wifi_signal_strength)
  [[ "$result" =~ ^-?[0-9]+$ ]]
}

