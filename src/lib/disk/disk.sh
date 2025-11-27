#!/usr/bin/env bash

if [[ -z "${LIB_DIR:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  UTILS_DIR="${SCRIPT_DIR}/../utils"
else
  UTILS_DIR="${LIB_DIR}/utils"
fi

source "${UTILS_DIR}/has-command.sh"
source "${UTILS_DIR}/platform-cache.sh"

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

get_disk_space_gb() {
  local path="${1:-/}"
  local os
  os="$(get_os)"
  local total_gb=0
  local used_gb=0
  local free_gb=0

  case "${os}" in
    Darwin*)
      if has_command df; then
        read -r total_gb used_gb free_gb < <(df -g "$path" 2>/dev/null | awk 'NR==2 {print int($2), int($3), int($4)}')
      fi
      ;;
    Linux*)
      if has_command df; then
        read -r total_gb used_gb free_gb < <(df -BG "$path" 2>/dev/null | awk 'NR==2 {gsub(/G/, "", $2); gsub(/G/, "", $3); gsub(/G/, "", $4); print int($2), int($3), int($4)}')
      fi
      ;;
  esac

  echo "${total_gb:-0} ${used_gb:-0} ${free_gb:-0}"
}

get_multiple_disks() {
  local os
  os="$(get_os)"
  local disks=""

  case "${os}" in
    Darwin*)
      if has_command df; then
        disks=$(df -h 2>/dev/null | awk 'NR>1 && $1 ~ /^\/dev\// && $9 !~ /^\/Volumes\// {print $1 ":" $9 ":" $5}')
      fi
      ;;
    Linux*)
      if has_command df; then
        disks=$(df -h 2>/dev/null | awk 'NR>1 && $1 ~ /^\/dev\// && $6 !~ /^\/boot/ && $6 !~ /^\/snap/ {print $1 ":" $6 ":" $5}')
      fi
      ;;
  esac

  echo "$disks"
}

get_disk_io() {
  local os
  os="$(get_os)"
  local read_kb=0
  local write_kb=0

  case "${os}" in
    Darwin*)
      if has_command iostat; then
        read -r read_kb write_kb < <(iostat -d 1 2 | awk 'NR>3 && /^disk/ {r+=$3; w+=$4} END {print int(r), int(w)}')
      fi
      ;;
    Linux*)
      if [[ -f /proc/diskstats ]]; then
        read -r read_kb write_kb < <(awk '{r+=$6; w+=$10} END {print int(r/2), int(w/2)}' /proc/diskstats)
      fi
      ;;
  esac

  echo "${read_kb} ${write_kb}"
}

export -f get_disk_usage
export -f get_disk_space_gb
export -f get_multiple_disks
export -f get_disk_io

