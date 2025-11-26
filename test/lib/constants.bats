#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../src/lib/constants.sh"
}

teardown() {
  cleanup_test_environment
}

@test "constants.sh - THRESHOLD_CRITICAL is set" {
  [[ -n "$THRESHOLD_CRITICAL" ]]
  [[ "$THRESHOLD_CRITICAL" == "80" ]]
}

@test "constants.sh - THRESHOLD_WARNING is set" {
  [[ -n "$THRESHOLD_WARNING" ]]
  [[ "$THRESHOLD_WARNING" == "50" ]]
}

@test "constants.sh - THRESHOLD_MEMORY_HIGH is set" {
  [[ -n "$THRESHOLD_MEMORY_HIGH" ]]
  [[ "$THRESHOLD_MEMORY_HIGH" == "60" ]]
}

@test "constants.sh - THRESHOLD_DISK_CRITICAL is set" {
  [[ -n "$THRESHOLD_DISK_CRITICAL" ]]
  [[ "$THRESHOLD_DISK_CRITICAL" == "90" ]]
}

@test "constants.sh - THRESHOLD_DISK_HIGH is set" {
  [[ -n "$THRESHOLD_DISK_HIGH" ]]
  [[ "$THRESHOLD_DISK_HIGH" == "75" ]]
}

@test "constants.sh - THRESHOLD_DISK_MEDIUM is set" {
  [[ -n "$THRESHOLD_DISK_MEDIUM" ]]
  [[ "$THRESHOLD_DISK_MEDIUM" == "50" ]]
}

@test "constants.sh - DEFAULT_BATTERY_LOW is set" {
  [[ -n "$DEFAULT_BATTERY_LOW" ]]
  [[ "$DEFAULT_BATTERY_LOW" == "21" ]]
}

@test "constants.sh - PRESSURE_CRITICAL_SWAPOUTS is set" {
  [[ -n "$PRESSURE_CRITICAL_SWAPOUTS" ]]
  [[ "$PRESSURE_CRITICAL_SWAPOUTS" == "5000000" ]]
}

@test "constants.sh - PRESSURE_WARNING_SWAPOUTS is set" {
  [[ -n "$PRESSURE_WARNING_SWAPOUTS" ]]
  [[ "$PRESSURE_WARNING_SWAPOUTS" == "1000000" ]]
}

@test "constants.sh - PRESSURE_CRITICAL_PSI is set" {
  [[ -n "$PRESSURE_CRITICAL_PSI" ]]
  [[ "$PRESSURE_CRITICAL_PSI" == "50" ]]
}

@test "constants.sh - PRESSURE_WARNING_PSI is set" {
  [[ -n "$PRESSURE_WARNING_PSI" ]]
  [[ "$PRESSURE_WARNING_PSI" == "10" ]]
}

@test "constants.sh - WEATHER_CACHE_TTL is set" {
  [[ -n "$WEATHER_CACHE_TTL" ]]
  [[ "$WEATHER_CACHE_TTL" == "900" ]]
}

@test "constants.sh - PING_CACHE_TTL is set" {
  [[ -n "$PING_CACHE_TTL" ]]
  [[ "$PING_CACHE_TTL" == "10" ]]
}

@test "constants.sh - CPU_ICONS array is set" {
  [[ -n "${CPU_ICONS[0]}" ]]
  [[ "${#CPU_ICONS[@]}" -eq 11 ]]
}

@test "constants.sh - GPU_ICONS array is set" {
  [[ -n "${GPU_ICONS[0]}" ]]
  [[ "${#GPU_ICONS[@]}" -eq 11 ]]
}

@test "constants.sh - MEMORY_ICONS array is set" {
  [[ -n "${MEMORY_ICONS[0]}" ]]
  [[ "${#MEMORY_ICONS[@]}" -eq 11 ]]
}

@test "constants.sh - LOAD_ICONS array is set" {
  [[ -n "${LOAD_ICONS[0]}" ]]
  [[ "${#LOAD_ICONS[@]}" -eq 11 ]]
}

@test "constants.sh - SWAP_ICONS array is set" {
  [[ -n "${SWAP_ICONS[0]}" ]]
  [[ "${#SWAP_ICONS[@]}" -eq 11 ]]
}

@test "constants.sh - DISK_ICONS array is set" {
  [[ -n "${DISK_ICONS[0]}" ]]
  [[ "${#DISK_ICONS[@]}" -eq 11 ]]
}

@test "constants.sh - BATTERY_ICONS array is set" {
  [[ -n "${BATTERY_ICONS[0]}" ]]
  [[ "${#BATTERY_ICONS[@]}" -eq 11 ]]
}

@test "constants.sh - GIT_CHANGES_ICONS array is set" {
  [[ -n "${GIT_CHANGES_ICONS[0]}" ]]
  [[ "${#GIT_CHANGES_ICONS[@]}" -eq 4 ]]
}

@test "constants.sh - GIT_INSERTIONS_ICONS array is set" {
  [[ -n "${GIT_INSERTIONS_ICONS[0]}" ]]
  [[ "${#GIT_INSERTIONS_ICONS[@]}" -eq 4 ]]
}

@test "constants.sh - GIT_DELETIONS_ICONS array is set" {
  [[ -n "${GIT_DELETIONS_ICONS[0]}" ]]
  [[ "${#GIT_DELETIONS_ICONS[@]}" -eq 4 ]]
}

@test "constants.sh - GIT_UNTRACKED_ICONS array is set" {
  [[ -n "${GIT_UNTRACKED_ICONS[0]}" ]]
  [[ "${#GIT_UNTRACKED_ICONS[@]}" -eq 3 ]]
}

@test "constants.sh - GIT_PR_ICONS array is set" {
  [[ -n "${GIT_PR_ICONS[0]}" ]]
  [[ "${#GIT_PR_ICONS[@]}" -eq 4 ]]
}

@test "constants.sh - GIT_REVIEW_ICONS array is set" {
  [[ -n "${GIT_REVIEW_ICONS[0]}" ]]
  [[ "${#GIT_REVIEW_ICONS[@]}" -eq 3 ]]
}

@test "constants.sh - GIT_ISSUE_ICONS array is set" {
  [[ -n "${GIT_ISSUE_ICONS[0]}" ]]
  [[ "${#GIT_ISSUE_ICONS[@]}" -eq 4 ]]
}

@test "constants.sh - ICON_BATTERY_PLUG is set" {
  [[ -n "$ICON_BATTERY_PLUG" ]]
}

@test "constants.sh - ICON_BATTERY_NO is set" {
  [[ -n "$ICON_BATTERY_NO" ]]
}

@test "constants.sh - ICON_WIFI_UP is set" {
  [[ -n "$ICON_WIFI_UP" ]]
}

@test "constants.sh - ICON_WIFI_DOWN is set" {
  [[ -n "$ICON_WIFI_DOWN" ]]
}

@test "constants.sh - ICON_WIRED_UP is set" {
  [[ -n "$ICON_WIRED_UP" ]]
}

@test "constants.sh - ICON_WIRED_DOWN is set" {
  [[ -n "$ICON_WIRED_DOWN" ]]
}

@test "constants.sh - ICON_TRAFFIC_TX is set" {
  [[ -n "$ICON_TRAFFIC_TX" ]]
}

@test "constants.sh - ICON_TRAFFIC_RX is set" {
  [[ -n "$ICON_TRAFFIC_RX" ]]
}

@test "constants.sh - ICON_IP is set" {
  [[ -n "$ICON_IP" ]]
}

@test "constants.sh - ICON_VPN is set" {
  [[ -n "$ICON_VPN" ]]
}

@test "constants.sh - ICON_PING is set" {
  [[ -n "$ICON_PING" ]]
}

@test "constants.sh - SEPARATOR_WIDGET is set" {
  [[ -n "$SEPARATOR_WIDGET" ]]
  [[ "$SEPARATOR_WIDGET" == "░" ]]
}

@test "constants.sh - DEFAULT_WINDOW_ID_STYLE is set" {
  [[ -n "$DEFAULT_WINDOW_ID_STYLE" ]]
  [[ "$DEFAULT_WINDOW_ID_STYLE" == "digital" ]]
}

@test "constants.sh - DEFAULT_PANE_ID_STYLE is set" {
  [[ -n "$DEFAULT_PANE_ID_STYLE" ]]
  [[ "$DEFAULT_PANE_ID_STYLE" == "hsquare" ]]
}

@test "constants.sh - DEFAULT_ZOOM_ID_STYLE is set" {
  [[ -n "$DEFAULT_ZOOM_ID_STYLE" ]]
  [[ "$DEFAULT_ZOOM_ID_STYLE" == "dsquare" ]]
}

@test "constants.sh - DEFAULT_DATE_FORMAT is set" {
  [[ -n "$DEFAULT_DATE_FORMAT" ]]
  [[ "$DEFAULT_DATE_FORMAT" == "YMD" ]]
}

@test "constants.sh - DEFAULT_TIME_FORMAT is set" {
  [[ -n "$DEFAULT_TIME_FORMAT" ]]
  [[ "$DEFAULT_TIME_FORMAT" == "24H" ]]
}

@test "constants.sh - DEFAULT_WEATHER_UNITS is set" {
  [[ -n "$DEFAULT_WEATHER_UNITS" ]]
  [[ "$DEFAULT_WEATHER_UNITS" == "m" ]]
}

@test "constants.sh - DEFAULT_NETSPEED_REFRESH is set" {
  [[ -n "$DEFAULT_NETSPEED_REFRESH" ]]
  [[ "$DEFAULT_NETSPEED_REFRESH" == "1" ]]
}

@test "constants.sh - DEFAULT_PATH_FORMAT is set" {
  [[ -n "$DEFAULT_PATH_FORMAT" ]]
  [[ "$DEFAULT_PATH_FORMAT" == "relative" ]]
}

