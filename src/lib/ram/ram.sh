#!/usr/bin/env bash

if [[ -z "${LIB_DIR:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  UTILS_DIR="${SCRIPT_DIR}/../utils"
else
  UTILS_DIR="${LIB_DIR}/utils"
fi

source "${UTILS_DIR}/has-command.sh"

get_total_memory_kb() {
  local os
  os="$(get_os)"

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
  os="$(get_os)"

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

get_memory_pressure() {
  local os
  os="$(get_os)"
  local pressure=0

  case "${os}" in
    Darwin*)
      if has_command memory_pressure; then
        pressure=$(memory_pressure 2>/dev/null | awk '/System-wide memory free percentage:/ {print $5}' | sed 's/%//')
      elif has_command vm_stat; then
        local pages_free pages_active pages_inactive pages_wired pages_compressed
        local page_size mem_total

        page_size=$(pagesize 2>/dev/null || sysctl -n hw.pagesize 2>/dev/null || echo "4096")
        mem_total=$(sysctl -n hw.memsize 2>/dev/null || echo "0")

        read -r pages_free pages_active pages_inactive pages_wired pages_compressed < <(vm_stat 2>/dev/null | awk '
          /Pages free:/ {free=$NF; gsub(/\./, "", free)}
          /Pages active:/ {active=$NF; gsub(/\./, "", active)}
          /Pages inactive:/ {inactive=$NF; gsub(/\./, "", inactive)}
          /Pages wired down:/ {wired=$NF; gsub(/\./, "", wired)}
          /Pages occupied by compressor:/ {compressed=$NF; gsub(/\./, "", compressed)}
          END {print free, active, inactive, wired, compressed}
        ')

        if [[ -n "$mem_total" ]] && [[ $mem_total -gt 0 ]]; then
          local mem_free
          mem_free=$(( (pages_free + pages_inactive) * page_size ))
          pressure=$(( (mem_free * 100) / mem_total ))
        fi
      fi
      ;;
    Linux*)
      if [[ -f /proc/pressure/memory ]]; then
        pressure=$(awk '/some/ {gsub(/total=/, "", $3); split($3, a, ","); print int(a[1]*100); exit}' /proc/pressure/memory 2>/dev/null)
      elif [[ -f /proc/meminfo ]]; then
        local mem_available mem_total
        mem_available=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null)
        mem_total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)
        if [[ -n "$mem_available" ]] && [[ -n "$mem_total" ]] && [[ $mem_total -gt 0 ]]; then
          pressure=$(( (mem_available * 100) / mem_total ))
        fi
      fi
      ;;
  esac

  [[ -n "$pressure" ]] && [[ "$pressure" =~ ^[0-9]+$ ]] && echo "$pressure" || echo "0"
}

export -f get_total_memory_kb
export -f get_active_memory_kb
export -f get_memory_pressure
