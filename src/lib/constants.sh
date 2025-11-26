#!/usr/bin/env bash

readonly THRESHOLD_CRITICAL=80
readonly THRESHOLD_WARNING=50
readonly THRESHOLD_MEMORY_HIGH=60

readonly THRESHOLD_DISK_CRITICAL=90
readonly THRESHOLD_DISK_HIGH=75
readonly THRESHOLD_DISK_MEDIUM=50

readonly DEFAULT_BATTERY_LOW=21

readonly PRESSURE_CRITICAL_SWAPOUTS=5000000
readonly PRESSURE_WARNING_SWAPOUTS=1000000

readonly PRESSURE_CRITICAL_PSI=50
readonly PRESSURE_WARNING_PSI=10

readonly WEATHER_CACHE_TTL=900
readonly PING_CACHE_TTL=10

readonly -a CPU_ICONS=(
  "󰾆" "󰾆" "󰾆" "󰾅" "󰾅"
  "󰾅" "󰾅" "󰾅" "󰀪" "󰀪" "󰀪"
)

readonly -a GPU_ICONS=(
  "󰢮" "󰢮" "󰢮" "󰢮" "󰢮"
  "󰘚" "󰘚" "󰘚" "󰘚" "󰀪" "󰀪"
)

readonly -a MEMORY_ICONS=(
  "󰍛" "󰍛" "󰍛" "󰍛" "󰍛"
  "󰍜" "󰍜" "󰍜" "󰍜" "󰀪" "󰀪"
)

readonly -a LOAD_ICONS=(
  "󰑮" "󰑮" "󰑮" "󰑮" "󰑮"
  "󰑮" "󰑮" "󰑮" "󰑮" "󰀪" "󰀪"
)

readonly -a SWAP_ICONS=(
  "󰾴" "󰾴" "󰾴" "󰾴" "󰾴"
  "󰾴" "󰾴" "󰾴" "󰾴" "󰀪" "󰀪"
)

readonly -a DISK_ICONS=(
  "󰋊" "󰋊" "󰋊" "󰋊" "󰋊"
  "󰪥" "󰪥" "󰪥" "󰪥" "󰀪" "󰀪"
)

readonly ICON_BATTERY_PLUG="󰚥"
readonly ICON_BATTERY_NO="󱉝"

readonly -a BATTERY_ICONS=(
  "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"
)

readonly ICON_WIFI_UP="󰖩"
readonly ICON_WIFI_DOWN="󰖪"
readonly ICON_WIRED_UP="󰈀"
readonly ICON_WIRED_DOWN="󰈂"
readonly ICON_TRAFFIC_TX="󰕒"
readonly ICON_TRAFFIC_RX="󰇚"
readonly ICON_IP="󰩟"
readonly ICON_VPN="󰌘"
readonly ICON_PING="󰓅"

readonly ICON_WEATHER_HOT="󰖙"
readonly ICON_WEATHER_SUN="󰖙"
readonly ICON_WEATHER_CLOUD_SUN="󰖐"
readonly ICON_WEATHER_CLOUD="󰖐"
readonly ICON_WEATHER_SNOW="󰜗"

readonly -a GIT_CHANGES_ICONS=(
  "󰄴"
  "󰄴"
  "󰄴"
  "󰀪"
)

readonly -a GIT_INSERTIONS_ICONS=(
  "󰐕"
  "󰐕"
  "󰐕"
  "󰀪"
)

readonly -a GIT_DELETIONS_ICONS=(
  "󰍵"
  "󰍵"
  "󰍵"
  "󰀪"
)

readonly -a GIT_UNTRACKED_ICONS=(
  "󰋗"
  "󰋗"
  "󰀪"
)

readonly -a GIT_PR_ICONS=(
  "󰊤"
  "󰊤"
  "󰊤"
  "󰀪"
)

readonly -a GIT_REVIEW_ICONS=(
  "󰭎"
  "󰭎"
  "󰀪"
)

readonly -a GIT_ISSUE_ICONS=(
  "󰀨"
  "󰀨"
  "󰀨"
  "󰀪"
)

readonly ICON_GIT_LOCAL_CHANGES="󱓎"
readonly ICON_GIT_PUSH="󰛃"
readonly ICON_GIT_PULL="󰛀"
readonly ICON_GIT_CLEAN=""

readonly ICON_DATETIME="󰃰"
readonly ICON_TIMEZONE="󰥔"
readonly ICON_MUSIC_PLAY="󰐊"
readonly ICON_MUSIC_PAUSE="󰏤"
readonly ICON_SSH="󰣀"
readonly ICON_CLIENTS="󰀫"
readonly ICON_SYNC="󰓦"
readonly ICON_PATH="󰉋"
readonly ICON_TEMPERATURE="󰏈"
readonly ICON_UPTIME="󰅐"
readonly ICON_PROCESS="󰅐"
readonly ICON_DOCKER="󰡨"
readonly ICON_KUBERNETES="󰠳"
readonly ICON_DISK_IO="󰋊"
readonly ICON_WIFI="󰖩"
readonly ICON_BLUETOOTH="󰂯"
readonly ICON_AUDIO="󰋋"
readonly ICON_BRIGHTNESS="󰃠"
readonly ICON_UPDATES="󰏕"
readonly ICON_STASH="󰆍"
readonly ICON_COMMIT="󰜘"
readonly ICON_HEALTH_OK="󰄲"
readonly ICON_HEALTH_WARNING="󰀝"
readonly ICON_HEALTH_CRITICAL="󰀪"
readonly ICON_CONNECTIONS="󰓅"
readonly ICON_FREQUENCY="󰾆"
readonly ICON_PRESSURE="󰍛"

readonly SEPARATOR_WIDGET="░"

readonly DEFAULT_WINDOW_ID_STYLE="digital"
readonly DEFAULT_PANE_ID_STYLE="hsquare"
readonly DEFAULT_ZOOM_ID_STYLE="dsquare"

readonly DEFAULT_DATE_FORMAT="YMD"
readonly DEFAULT_TIME_FORMAT="24H"

readonly DEFAULT_WEATHER_UNITS="m"
readonly DEFAULT_NETSPEED_REFRESH=1
readonly DEFAULT_PATH_FORMAT="relative"

export THRESHOLD_CRITICAL THRESHOLD_WARNING THRESHOLD_MEMORY_HIGH
export THRESHOLD_DISK_CRITICAL THRESHOLD_DISK_HIGH THRESHOLD_DISK_MEDIUM
export DEFAULT_BATTERY_LOW
export PRESSURE_CRITICAL_SWAPOUTS PRESSURE_WARNING_SWAPOUTS
export PRESSURE_CRITICAL_PSI PRESSURE_WARNING_PSI
export WEATHER_CACHE_TTL PING_CACHE_TTL
export SEPARATOR_WIDGET
