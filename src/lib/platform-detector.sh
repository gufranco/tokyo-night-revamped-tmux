#!/usr/bin/env bash

declare -gA PLATFORM_CACHE

has_command() {
  local cmd="${1}"
  
  if [[ -n "${PLATFORM_CACHE[${cmd}]}" ]]; then
    return "${PLATFORM_CACHE[${cmd}]}"
  fi
  
  if command -v "${cmd}" &>/dev/null; then
    PLATFORM_CACHE["${cmd}"]=0
    return 0
  else
    PLATFORM_CACHE["${cmd}"]=1
    return 1
  fi
}

get_default_network_interface() {
  local os
  os="$(uname -s)"
  
  case "${os}" in
    Darwin*)
      route -n get default 2>/dev/null | awk '/interface:/ {print $2}' || echo "en0"
      ;;
    Linux*)
      if [[ -f /proc/net/route ]]; then
        awk '$2 == "00000000" {print $1; exit}' /proc/net/route 2>/dev/null || echo "eth0"
      else
        echo "eth0"
      fi
      ;;
    *)
      echo "eth0"
      ;;
  esac
}

get_cpu_count() {
  local os
  os="$(uname -s)"
  
  case "${os}" in
    Darwin*)
      sysctl -n hw.ncpu 2>/dev/null || echo "1"
      ;;
    Linux*)
      grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1"
      ;;
    *)
      echo "1"
      ;;
  esac
}

get_total_memory_kb() {
  local os
  os="$(uname -s)"
  
  case "${os}" in
    Darwin*)
      local mem_bytes
      mem_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
      echo $(( mem_bytes / 1024 ))
      ;;
    Linux*)
      awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0"
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_active_memory_kb() {
  local os
  os="$(uname -s)"
  
  case "${os}" in
    Darwin*)
      local page_size active wired compressed
      page_size=$(pagesize 2>/dev/null || sysctl -n hw.pagesize 2>/dev/null || echo "4096")
      
      local vm_output
      vm_output=$(vm_stat 2>/dev/null)
      
      active=$(echo "${vm_output}" | awk '/Pages active:/ {print $NF}' | tr -d '.')
      wired=$(echo "${vm_output}" | awk '/Pages wired down:/ {print $NF}' | tr -d '.')
      compressed=$(echo "${vm_output}" | awk '/Pages occupied by compressor:/ {print $NF}' | tr -d '.')
      
      active=${active:-0}
      wired=${wired:-0}
      compressed=${compressed:-0}
      
      echo $(( (active + wired + compressed) * page_size / 1024 ))
      ;;
    Linux*)
      awk '
        /MemTotal:/ {total=$2}
        /MemAvailable:/ {available=$2}
        END {print total - available}
      ' /proc/meminfo 2>/dev/null || echo "0"
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_cpu_usage_percentage() {
  local os
  os="$(uname -s)"
  
  case "${os}" in
    Darwin*)
      local cpu_line cpu_user cpu_sys
      cpu_line=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage")
      cpu_user=$(echo "$cpu_line" | awk '{print $3}' | sed 's/%//')
      cpu_sys=$(echo "$cpu_line" | awk '{print $5}' | sed 's/%//')

      if command -v bc >/dev/null 2>&1; then
        echo "$cpu_user + $cpu_sys" | bc | cut -d'.' -f1
      else
        awk "BEGIN {printf \"%.0f\", $cpu_user + $cpu_sys}"
      fi
      ;;
    Linux*)
      if [[ -f /proc/stat ]]; then
        awk '
          /^cpu / {
            idle=$5
            total=0
            for(i=2;i<=NF;i++) total+=$i
            if (total > 0) {
              usage = 100 * (total - idle) / total
              print int(usage)
            } else {
              print 0
            }
            exit
          }
        ' /proc/stat 2>/dev/null || echo "0"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_load_average() {
  local os
  os="$(uname -s)"
  
  case "${os}" in
    Darwin*)
      sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}' || echo "0"
      ;;
    Linux*)
      if [[ -f /proc/loadavg ]]; then
        awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_disk_usage() {
  local path="${1:-/}"
  
  if has_command df; then
    df -k "${path}" 2>/dev/null | awk 'NR==2 {
      used_gb = int($3 / 1048576)
      total_gb = int($2 / 1048576)
      if (total_gb > 0) {
        percent = int(($3 * 100) / $2)
      } else {
        percent = 0
      }
      print used_gb " " total_gb " " percent
    }' || echo "0 0 0"
  else
    echo "0 0 0"
  fi
}

export -f has_command
export -f get_default_network_interface
export -f get_cpu_count
export -f get_total_memory_kb
export -f get_active_memory_kb
export -f get_cpu_usage_percentage
export -f get_load_average
export -f get_disk_usage

