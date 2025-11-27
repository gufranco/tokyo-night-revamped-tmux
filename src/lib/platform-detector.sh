#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}"

source "${LIB_DIR}/utils/has-command.sh"
source "${LIB_DIR}/utils/platform-cache.sh"

source "${LIB_DIR}/cpu/cpu.sh"
source "${LIB_DIR}/gpu/gpu.sh"
source "${LIB_DIR}/ram/ram.sh"
source "${LIB_DIR}/disk/disk.sh"
source "${LIB_DIR}/network/network.sh"

get_system_uptime() {
  local os
  os="$(get_os)"
  local uptime_seconds=0

  case "${os}" in
    Darwin*)
      uptime_seconds=$(sysctl -n kern.boottime 2>/dev/null | awk '{print $4}' | sed 's/,//')
      if [[ -n "$uptime_seconds" ]] && [[ "$uptime_seconds" =~ ^[0-9]+$ ]]; then
        current_time=$(date +%s)
        uptime_seconds=$(( current_time - uptime_seconds ))
      else
        uptime_seconds=0
      fi
      ;;
    Linux*)
      if [[ -f /proc/uptime ]]; then
        uptime_seconds=$(awk '{print int($1)}' /proc/uptime 2>/dev/null)
      fi
      ;;
  esac

  echo "${uptime_seconds:-0}"
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
  local os
  os="$(get_os)"
  local processes=""

  case "${os}" in
    Darwin*)
      processes=$(ps aux 2>/dev/null | sort -rk 3,3 | head -n $((count + 1)) | tail -n $count | awk '{printf "%s:%s ", $11, int($3)}')
      ;;
    Linux*)
      processes=$(ps aux 2>/dev/null | sort -rk 3,3 | head -n $((count + 1)) | tail -n $count | awk '{printf "%s:%s ", $11, int($3)}')
      ;;
  esac

  echo "$processes"
}

get_docker_containers() {
  if ! has_command docker; then
    echo "0"
    return
  fi

  docker ps -q 2>/dev/null | wc -l | tr -d ' '
}

get_kubernetes_pods() {
  if ! has_command kubectl; then
    echo "0"
    return
  fi

  kubectl get pods --all-namespaces --field-selector=status.phase=Running -o json 2>/dev/null | grep -c '"phase":"Running"' || echo "0"
}

get_system_health_status() {
  local cpu_usage mem_usage disk_usage temp_cpu temp_gpu
  local health_status="ok"
  local issues=0

  cpu_usage=$(get_cpu_usage_percentage)
  mem_usage=$(get_active_memory_kb)
  local mem_total
  mem_total=$(get_total_memory_kb)
  if [[ -n "$mem_total" ]] && [[ $mem_total -gt 0 ]]; then
    mem_usage=$(( (mem_usage * 100) / mem_total ))
  else
    mem_usage=0
  fi

  disk_usage=$(df -h / 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5}')
  temp_cpu=$(get_cpu_temperature)
  temp_gpu=$(get_gpu_temperature)

  if (( cpu_usage >= 90 )) || (( mem_usage >= 90 )) || (( disk_usage >= 90 )) || (( temp_cpu >= 85 )) || (( temp_gpu >= 85 )); then
    health_status="critical"
    issues=$((issues + 1))
  elif (( cpu_usage >= 75 )) || (( mem_usage >= 75 )) || (( disk_usage >= 75 )) || (( temp_cpu >= 70 )) || (( temp_gpu >= 70 )); then
    health_status="warning"
    issues=$((issues + 1))
  fi

  echo "${health_status}|${issues}"
}

export -f get_system_uptime
export -f format_uptime
export -f get_top_processes
export -f get_docker_containers
export -f get_kubernetes_pods
export -f get_system_health_status
