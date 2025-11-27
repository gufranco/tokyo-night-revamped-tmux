#!/usr/bin/env bash

setup_test_environment() {
  TEST_TMPDIR=$(mktemp -d)
  export TEST_TMPDIR

  TEST_SRC_DIR="${TEST_TMPDIR}/src"
  TEST_LIB_DIR="${TEST_SRC_DIR}/lib"
  mkdir -p "${TEST_LIB_DIR}"

  export SCRIPT_DIR="${TEST_SRC_DIR}"
  export LIB_DIR="${TEST_LIB_DIR}"

  export TMUX_TEST_MODE=1
}

cleanup_test_environment() {
  if [[ -n "$TEST_TMPDIR" ]] && [[ -d "$TEST_TMPDIR" ]]; then
    rm -rf "$TEST_TMPDIR"
  fi
}

tmux() {
  if [[ "$1" == "show-option" ]]; then
    local option_name="$3"
    case "$option_name" in
      @tokyo-night-tmux_refresh_rate)
        echo "${TMUX_REFRESH_RATE:-5}"
        ;;
      @tokyo-night-tmux_show_context)
        echo "${TMUX_SHOW_CONTEXT:-1}"
        ;;
      @tokyo-night-tmux_show_git)
        echo "${TMUX_SHOW_GIT:-1}"
        ;;
      @tokyo-night-tmux_show_netspeed)
        echo "${TMUX_SHOW_NETSPEED:-1}"
        ;;
      @tokyo-night-tmux_show_system)
        echo "${TMUX_SHOW_SYSTEM:-1}"
        ;;
      @tokyo-night-tmux_minimal_session)
        echo "${TMUX_MINIMAL_SESSION:-}"
        ;;
      @tokyo-night-tmux_context_weather)
        echo "${TMUX_CONTEXT_WEATHER:-1}"
        ;;
      @tokyo-night-tmux_context_weather_units)
        echo "${TMUX_CONTEXT_WEATHER_UNITS:-m}"
        ;;
      @tokyo-night-tmux_context_date_format)
        echo "${TMUX_CONTEXT_DATE_FORMAT:-YMD}"
        ;;
      @tokyo-night-tmux_context_time_format)
        echo "${TMUX_CONTEXT_TIME_FORMAT:-24H}"
        ;;
      @tokyo-night-tmux_context_timezone)
        echo "${TMUX_CONTEXT_TIMEZONE:-0}"
        ;;
      @tokyo-night-tmux_context_timezones)
        echo "${TMUX_CONTEXT_TIMEZONES:-}"
        ;;
      @tokyo-night-tmux_git_untracked)
        echo "${TMUX_GIT_UNTRACKED:-1}"
        ;;
      @tokyo-night-tmux_git_web)
        echo "${TMUX_GIT_WEB:-1}"
        ;;
      @tokyo-night-tmux_netspeed_iface)
        echo "${TMUX_NETSPEED_IFACE:-}"
        ;;
      @tokyo-night-tmux_netspeed_ping)
        echo "${TMUX_NETSPEED_PING:-0}"
        ;;
      @tokyo-night-tmux_netspeed_vpn)
        echo "${TMUX_NETSPEED_VPN:-1}"
        ;;
      @tokyo-night-tmux_system_cpu)
        echo "${TMUX_SYSTEM_CPU:-1}"
        ;;
      @tokyo-night-tmux_system_load)
        echo "${TMUX_SYSTEM_LOAD:-1}"
        ;;
      @tokyo-night-tmux_system_gpu)
        echo "${TMUX_SYSTEM_GPU:-1}"
        ;;
      @tokyo-night-tmux_system_memory)
        echo "${TMUX_SYSTEM_MEMORY:-1}"
        ;;
      @tokyo-night-tmux_system_swap)
        echo "${TMUX_SYSTEM_SWAP:-1}"
        ;;
      @tokyo-night-tmux_system_disk)
        echo "${TMUX_SYSTEM_DISK:-1}"
        ;;
      @tokyo-night-tmux_system_disk_path)
        echo "${TMUX_SYSTEM_DISK_PATH:-/}"
        ;;
      @tokyo-night-tmux_system_battery)
        echo "${TMUX_SYSTEM_BATTERY:-1}"
        ;;
      @tokyo-night-tmux_system_battery_name)
        echo "${TMUX_SYSTEM_BATTERY_NAME:-}"
        ;;
      @tokyo-night-tmux_system_battery_threshold)
        echo "${TMUX_SYSTEM_BATTERY_THRESHOLD:-21}"
        ;;
      @tokyo-night-tmux_theme)
        echo "${TMUX_THEME:-night}"
        ;;
      @tokyo-night-tmux_compact_mode)
        echo "${TMUX_COMPACT_MODE:-0}"
        ;;
      @tokyo-night-tmux_enable_logging)
        echo "${TMUX_ENABLE_LOGGING:-0}"
        ;;
      @tokyo-night-tmux_enable_profiling)
        echo "${TMUX_ENABLE_PROFILING:-0}"
        ;;
      @tokyo-night-tmux_show_health)
        echo "${TMUX_SHOW_HEALTH:-0}"
        ;;
      @tokyo-night-tmux_system_health)
        echo "${TMUX_SYSTEM_HEALTH:-0}"
        ;;
      @tokyo-night-tmux_system_frequency)
        echo "${TMUX_SYSTEM_FREQUENCY:-0}"
        ;;
      @tokyo-night-tmux_system_pressure)
        echo "${TMUX_SYSTEM_PRESSURE:-0}"
        ;;
      @tokyo-night-tmux_system_disk_space)
        echo "${TMUX_SYSTEM_DISK_SPACE:-0}"
        ;;
      @tokyo-night-tmux_system_connections)
        echo "${TMUX_SYSTEM_CONNECTIONS:-0}"
        ;;
      @tokyo-night-tmux_system_multiple_disks)
        echo "${TMUX_SYSTEM_MULTIPLE_DISKS:-0}"
        ;;
      @tokyo-night-tmux_threshold_critical)
        echo "${TMUX_THRESHOLD_CRITICAL:-80}"
        ;;
      @tokyo-night-tmux_threshold_warning)
        echo "${TMUX_THRESHOLD_WARNING:-50}"
        ;;
      @tokyo-night-tmux_threshold_high)
        echo "${TMUX_THRESHOLD_HIGH:-75}"
        ;;
      @tokyo-night-tmux_netspeed_connections)
        echo "${TMUX_NETSPEED_CONNECTIONS:-0}"
        ;;
      @tokyo-night-tmux_netspeed_show_interface)
        echo "${TMUX_NETSPEED_SHOW_INTERFACE:-0}"
        ;;
      @tokyo-night-tmux_enable_trends)
        echo "${TMUX_ENABLE_TRENDS:-0}"
        ;;
      @test_option)
        echo "${TMUX_SHOW_OPTION_VALUE:-}"
        ;;
      *)
        echo "${TMUX_SHOW_OPTION_VALUE:-}"
        ;;
    esac
  elif [[ "$1" == "display-message" ]]; then
    echo "${TMUX_CURRENT_SESSION:-test-session}"
  elif [[ "$1" == "set-option" ]]; then
    return 0
  fi
}

date() {
  if [[ "$1" == "+%s" ]]; then
    echo "${MOCK_CURRENT_TIME:-$(command date +%s)}"
  elif [[ "$1" == "+%Y-%m-%d" ]]; then
    echo "${MOCK_DATE_YMD:-2024-01-15}"
  elif [[ "$1" == "+%H:%M" ]]; then
    echo "${MOCK_TIME_24H:-14:30}"
  elif [[ "$1" == "+%I:%M %p" ]]; then
    echo "${MOCK_TIME_12H:-02:30 PM}"
  elif [[ "$1" =~ ^\+%-H ]]; then
    echo "${MOCK_HOUR:-14}"
  elif [[ "$1" =~ ^\+%H:%M ]]; then
    echo "${MOCK_TIME_24H:-14:30}"
  elif [[ "$1" =~ ^\+%Z ]]; then
    echo "${MOCK_TIMEZONE:-UTC}"
  elif [[ "$1" =~ ^\+%u ]]; then
    echo "${MOCK_DAY_OF_WEEK:-1}"
  else
    command date "$@"
  fi
}

stat() {
  if [[ "$1" == "-f" ]] && [[ "$2" == "%m" ]]; then
    echo "${MOCK_FILE_MTIME:-$(command date +%s)}"
  elif [[ "$1" == "-c" ]] && [[ "$2" == "%Y" ]]; then
    echo "${MOCK_FILE_MTIME:-$(command date +%s)}"
  else
    command stat "$@"
  fi
}

git() {
  case "$1" in
    rev-parse)
      if [[ "$2" == "--abbrev-ref" ]]; then
        echo "${MOCK_GIT_BRANCH:-main}"
      elif [[ "$2" == "--git-dir" ]]; then
        if [[ "${MOCK_GIT_REPO:-1}" == "1" ]]; then
          echo ".git"
          return 0
        else
          return 1
        fi
      fi
      ;;
    status)
      if [[ "$2" == "--porcelain" ]]; then
        echo "${MOCK_GIT_STATUS:-}"
      fi
      ;;
    diff)
      if [[ "$2" == "--numstat" ]]; then
        echo "${MOCK_GIT_DIFF_NUMSTAT:-}"
      fi
      ;;
    ls-files)
      if [[ "$2" == "--other" ]]; then
        echo "${MOCK_GIT_UNTRACKED_FILES:-}"
      fi
      ;;
    config)
      if [[ "$2" == "remote.origin.url" ]]; then
        echo "${MOCK_GIT_REMOTE_URL:-}"
      fi
      ;;
    *)
      command git "$@" 2>/dev/null
      ;;
  esac
}

uname() {
  case "$1" in
    -s)
      echo "${MOCK_UNAME_S:-Darwin}"
      ;;
    -m)
      echo "${MOCK_UNAME_M:-arm64}"
      ;;
    "")
      echo "${MOCK_UNAME_S:-Darwin}"
      ;;
    *)
      command uname "$@"
      ;;
  esac
}

curl() {
  if [[ "$1" == "-sf" ]]; then
    echo "${MOCK_CURL_OUTPUT:-+15°C}"
  else
    command curl "$@"
  fi
}

wget() {
  if [[ "$1" == "-qO-" ]]; then
    echo "${MOCK_WGET_OUTPUT:-+15°C}"
  else
    command wget "$@"
  fi
}

ping() {
  if [[ "$1" == "-c" ]] && [[ "$2" == "1" ]]; then
    echo "PING 8.8.8.8: time=${MOCK_PING_TIME:-10}ms"
  else
    command ping "$@"
  fi
}

sysctl() {
  case "$2" in
    hw.ncpu)
      echo "${MOCK_CPU_COUNT:-8}"
      ;;
    hw.memsize)
      echo "${MOCK_MEM_TOTAL:-17179869184}"
      ;;
    hw.pagesize)
      echo "${MOCK_PAGE_SIZE:-4096}"
      ;;
    vm.swapusage)
      echo "total = ${MOCK_SWAP_TOTAL:-4096.00M}  used = ${MOCK_SWAP_USED:-1024.00M}"
      ;;
    vm.loadavg)
      echo "{ 1.5 1.2 1.0 }"
      ;;
    *)
      command sysctl "$@"
      ;;
  esac
}

vm_stat() {
  cat <<EOF
Pages free:                         12345.
Pages active:                       67890.
Pages inactive:                     23456.
Pages wired down:                   34567.
Pages occupied by compressor:      12345.
EOF
}

df() {
  if [[ "$1" == "-h" ]]; then
    echo "Filesystem      Size  Used Avail Use% Mounted on"
    echo "/dev/disk1      500G  250G  250G  50% /"
  else
    command df "$@"
  fi
}

netstat() {
  if [[ "$1" == "-ib" ]]; then
    echo "Name  Mtu   Network       Address            Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll"
    echo "en0   1500  <Link#6>      aa:bb:cc:dd:ee:ff  12345     0   123456789  12345     0   987654321     0"
  elif [[ "$1" == "-rn" ]] && [[ "$2" == "-f" ]]; then
    echo "${MOCK_NETSTAT_ROUTES:-}"
  else
    command netstat "$@"
  fi
}

route() {
  if [[ "$1" == "get" ]] && [[ "$2" == "default" ]]; then
    echo "   route to: default"
    echo "destination: default"
    echo "       mask: default"
    echo "    gateway: 192.168.1.1"
    echo "  interface: ${MOCK_ROUTE_INTERFACE:-en0}"
  else
    command route "$@"
  fi
}

awk() {
  command awk "$@"
}

grep() {
  command grep "$@"
}

cat() {
  command cat "$@"
}

head() {
  command head "$@"
}

tail() {
  command tail "$@"
}

wc() {
  if [[ "$1" == "-l" ]]; then
    echo "${MOCK_WC_LINES:-0}"
  else
    command wc "$@"
  fi
}

ps() {
  if [[ "$1" == "axo" ]]; then
    echo "${MOCK_PS_OUTPUT:-}"
  else
    command ps "$@"
  fi
}

get_cpu_temperature() {
  echo "${MOCK_CPU_TEMP:-45}"
}

get_gpu_temperature() {
  echo "${MOCK_GPU_TEMP:-50}"
}

get_system_uptime() {
  echo "${MOCK_UPTIME:-3600}"
}

format_uptime() {
  local seconds=$1
  local days=$(( seconds / 86400 ))
  local hours=$(( (seconds % 86400) / 3600 ))
  local minutes=$(( (seconds % 3600) / 60 ))
  
  if [[ $days -gt 0 ]]; then
    echo "${days}d ${hours}h ${minutes}m"
  elif [[ $hours -gt 0 ]]; then
    echo "${hours}h ${minutes}m"
  else
    echo "${minutes}m"
  fi
}

get_top_processes() {
  local count=${1:-3}
  echo "node:45 python:23 chrome:12"
}

get_docker_containers() {
  echo "${MOCK_DOCKER_CONTAINERS:-0}"
}

get_kubernetes_pods() {
  echo "${MOCK_KUBERNETES_PODS:-0}"
}

get_disk_io() {
  echo "${MOCK_DISK_IO_READ:-1000} ${MOCK_DISK_IO_WRITE:-500}"
}

get_vpn_connection_name() {
  echo "${MOCK_VPN_NAME:-}"
}

get_wifi_signal_strength() {
  echo "${MOCK_WIFI_SIGNAL:--65}"
}


get_network_connections() {
  echo "${MOCK_NETWORK_CONNECTIONS:-0}"
}

get_cpu_frequency() {
  echo "${MOCK_CPU_FREQUENCY:-2400}"
}

get_disk_space_gb() {
  local path="${1:-/}"
  echo "${MOCK_DISK_TOTAL_GB:-500} ${MOCK_DISK_USED_GB:-250} ${MOCK_DISK_FREE_GB:-250}"
}

get_memory_pressure() {
  echo "${MOCK_MEMORY_PRESSURE:-50}"
}

get_system_health_status() {
  echo "${MOCK_HEALTH_STATUS:-ok|0}"
}

get_multiple_disks() {
  echo "${MOCK_MULTIPLE_DISKS:-/dev/disk1:/:50%}"
}

get_default_network_interface() {
  echo "${MOCK_DEFAULT_INTERFACE:-en0}"
}

kubectl() {
  if [[ "$1" == "get" ]] && [[ "$2" == "pods" ]]; then
    echo "${MOCK_KUBECTL_PODS:-0}"
  else
    command kubectl "$@"
  fi
}

softwareupdate() {
  if [[ "$1" == "-l" ]]; then
    echo "${MOCK_SOFTWAREUPDATE_OUTPUT:-}"
  else
    command softwareupdate "$@"
  fi
}

route() {
  if [[ "$1" == "-n" ]] && [[ "$2" == "get" ]] && [[ "$3" == "default" ]]; then
    echo "${MOCK_ROUTE_OUTPUT:-interface: en0}"
  else
    command route "$@"
  fi
}

top() {
  if [[ "$1" == "-l" ]] && [[ "$2" == "1" ]]; then
    echo "CPU usage: ${MOCK_TOP_CPU_USER:-10.5}% user, ${MOCK_TOP_CPU_SYS:-5.2}% sys"
  else
    command top "$@"
  fi
}

pmset() {
  if [[ "$1" == "-g" ]] && [[ "$2" == "batt" ]]; then
    echo "Now drawing from 'AC Power'"
    echo " -InternalBattery-0 (id=${MOCK_BATTERY_ID:-12345}) ${MOCK_BATTERY_STATUS:-charged}; ${MOCK_BATTERY_PERCENT:-100}%; ${MOCK_BATTERY_TIME:-0:00} remaining"
  else
    command pmset "$@"
  fi
}

ipconfig() {
  if [[ "$1" == "getifaddr" ]]; then
    echo "${MOCK_IPCONFIG_IP:-192.168.1.100}"
  else
    command ipconfig "$@"
  fi
}

ip() {
  if [[ "$1" == "addr" ]] && [[ "$2" == "show" ]]; then
    echo "${MOCK_IP_ADDR_OUTPUT:-}"
  elif [[ "$1" == "link" ]] && [[ "$2" == "show" ]]; then
    echo "${MOCK_IP_LINK_OUTPUT:-}"
  else
    command ip "$@"
  fi
}

ifconfig() {
  echo "${MOCK_IFCONFIG_OUTPUT:-}"
}

free() {
  echo "              total        used        free      shared  buff/cache   available"
  echo "Mem:        ${MOCK_FREE_MEM_TOTAL:-8192}      ${MOCK_FREE_MEM_USED:-4096}      ${MOCK_FREE_MEM_FREE:-2048}         ${MOCK_FREE_MEM_SHARED:-512}      ${MOCK_FREE_MEM_BUFF:-1024}      ${MOCK_FREE_MEM_AVAIL:-3072}"
  echo "Swap:       ${MOCK_FREE_SWAP_TOTAL:-2048}      ${MOCK_FREE_SWAP_USED:-512}      ${MOCK_FREE_SWAP_FREE:-1536}"
}

ioreg() {
  if [[ "$1" == "-r" ]] && [[ "$2" == "-d" ]]; then
    echo "${MOCK_IOREG_OUTPUT:-}"
  else
    command ioreg "$@"
  fi
}

pagesize() {
  echo "${MOCK_PAGESIZE:-4096}"
}

gh() {
  case "$1" in
    pr)
      if [[ "$2" == "list" ]]; then
        echo "${MOCK_GH_PR_LIST:-[]}"
      elif [[ "$2" == "status" ]]; then
        echo "${MOCK_GH_PR_STATUS:-{\"needsReview\":[]}}"
      fi
      ;;
    issue)
      if [[ "$2" == "list" ]]; then
        echo "${MOCK_GH_ISSUE_LIST:-[]}"
      fi
      ;;
    *)
      command gh "$@"
      ;;
  esac
}

glab() {
  case "$1" in
    mr)
      if [[ "$2" == "list" ]]; then
        echo "${MOCK_GLAB_MR_LIST:-}"
      fi
      ;;
    issue)
      if [[ "$2" == "list" ]]; then
        echo "${MOCK_GLAB_ISSUE_LIST:-}"
      fi
      ;;
    *)
      command glab "$@"
      ;;
  esac
}

jq() {
  if [[ -n "${MOCK_JQ_OUTPUT:-}" ]]; then
    echo "${MOCK_JQ_OUTPUT}"
  else
    command jq "$@" 2>/dev/null || echo "0"
  fi
}

load_lib() {
  local lib_file="$1"
  local real_lib_path="${BATS_TEST_DIRNAME}/../src/lib/${lib_file}"

  if [[ ! -f "$real_lib_path" ]]; then
    return 0
  fi

  case "$lib_file" in
    cache.sh)
      if ! declare -f is_macos >/dev/null 2>&1; then
        is_macos() {
          [[ "$OSTYPE" == "darwin"* ]]
        }
      fi
      if ! declare -f get_current_timestamp >/dev/null 2>&1; then
        local coreutils_path="${BATS_TEST_DIRNAME}/../src/lib/coreutils-compat.sh"
        [[ -f "$coreutils_path" ]] && source "$coreutils_path" 2>/dev/null || true
      fi
      ;;
    color-scale.sh)
      if [[ -z "${THEME[@]:-}" ]]; then
        local constants_path="${BATS_TEST_DIRNAME}/../src/lib/utils/constants.sh"
        local themes_path="${BATS_TEST_DIRNAME}/../src/lib/ui/themes.sh"
        [[ -f "$constants_path" ]] && source "$constants_path" 2>/dev/null || true
        [[ -f "$themes_path" ]] && source "$themes_path" 2>/dev/null || true
      fi
      ;;
  esac

  source "$real_lib_path" 2>/dev/null || true
}

load_widget() {
  local widget_file="$1"
  local real_widget_path="${BATS_TEST_DIRNAME}/../src/${widget_file}"

  if [[ -f "$real_widget_path" ]]; then
    local test_widget_path="${TEST_SRC_DIR}/${widget_file}"
    cp "$real_widget_path" "$test_widget_path"
    source "$test_widget_path"
  fi
}

function_exists() {
  declare -f "$1" > /dev/null
}

variable_exists() {
  [[ -n "${!1:-}" ]]
}

create_test_cache_file() {
  local cache_file="$1"
  local content="${2:-test content}"
  local mtime="${3:-}"

  echo "$content" > "$cache_file"

  if [[ -n "$mtime" ]]; then
    touch -t "$(date -r "$mtime" +%Y%m%d%H%M.%S)" "$cache_file" 2>/dev/null || \
    touch -d "@$mtime" "$cache_file" 2>/dev/null || true
  fi
}

create_test_git_repo() {
  local repo_dir="$1"

  mkdir -p "$repo_dir"
  cd "$repo_dir" || return 1

  git init --quiet
  git config user.name "Test User"
  git config user.email "test@example.com"

  echo "test file" > test.txt
  git add test.txt
  git commit -m "Initial commit" --quiet

  export MOCK_GIT_REPO=1
  export MOCK_GIT_BRANCH="main"
}

create_test_network_interface() {
  local interface="$1"
  local rx_bytes="${2:-0}"
  local tx_bytes="${3:-0}"

  export MOCK_NETSTAT_OUTPUT="Name  Mtu   Network       Address            Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll
${interface}   1500  <Link#6>      aa:bb:cc:dd:ee:ff  12345     0   ${rx_bytes}  12345     0   ${tx_bytes}     0"
}

export -f tmux
export -f date
export -f stat
export -f git
export -f uname
export -f curl
export -f wget
export -f ping
export -f sysctl
export -f vm_stat
export -f df
export -f netstat
export -f route
export -f awk
export -f grep
export -f cat
export -f head
export -f tail
export -f wc
export -f ps
export -f top
export -f pmset
export -f ipconfig
export -f ip
export -f ifconfig
export -f free
export -f ioreg
export -f pagesize
export -f gh
export -f glab
export -f jq
