#!/usr/bin/env bash

readonly HISTORICAL_DATA_DIR="${HOME}/.tmux/yoru-data"
readonly MAX_HISTORY_POINTS=100

mkdir -p "$HISTORICAL_DATA_DIR" 2>/dev/null

sanitize_metric_name() {
  local name="${1:-}"
  name="${name//[^a-zA-Z0-9_-]/}"
  name="${name:0:50}"
  echo "$name"
}

save_historical_point() {
  local metric_name="${1:-}"
  local value="${2:-0}"

  if [[ -z "$metric_name" ]]; then
    return 1
  fi

  metric_name=$(sanitize_metric_name "$metric_name")

  if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
    return 1
  fi

  local timestamp
  timestamp=$(date +%s 2>/dev/null || echo "0")

  if [[ $timestamp -eq 0 ]]; then
    return 1
  fi

  local data_file="${HISTORICAL_DATA_DIR}/${metric_name}.csv"

  if [[ ! -w "$HISTORICAL_DATA_DIR" ]] 2>/dev/null; then
    return 1
  fi

  echo "${timestamp},${value}" >> "$data_file" 2>/dev/null

  local line_count
  line_count=$(wc -l < "$data_file" 2>/dev/null | tr -d ' ')
  if [[ -n "$line_count" ]] && [[ "$line_count" =~ ^[0-9]+$ ]] && [[ $line_count -gt $MAX_HISTORICAL_POINTS ]]; then
    tail -n "$MAX_HISTORICAL_POINTS" "$data_file" > "${data_file}.tmp" 2>/dev/null
    mv "${data_file}.tmp" "$data_file" 2>/dev/null
  fi
}

get_historical_trend() {
  local metric_name="${1:-}"
  local trend="stable"

  if [[ -z "$metric_name" ]]; then
    echo "$trend"
    return
  fi

  metric_name=$(sanitize_metric_name "$metric_name")
  local data_file="${HISTORICAL_DATA_DIR}/${metric_name}.csv"

  if [[ ! -f "$data_file" ]] || [[ ! -r "$data_file" ]]; then
    echo "$trend"
    return
  fi

  local recent_values
  recent_values=$(tail -n 5 "$data_file" 2>/dev/null | cut -d',' -f2)

  if [[ -z "$recent_values" ]]; then
    echo "$trend"
    return
  fi

  local values=()
  while IFS= read -r value; do
    [[ -n "$value" ]] && [[ "$value" =~ ^[0-9]+$ ]] && values+=("$value")
  done <<< "$recent_values"

  if [[ ${#values[@]} -lt 2 ]]; then
    echo "$trend"
    return
  fi

  local first=${values[0]}
  local last=${values[-1]}

  if (( last > first + 5 )); then
    trend="up"
  elif (( last < first - 5 )); then
    trend="down"
  fi

  echo "$trend"
}

get_historical_average() {
  local metric_name="${1:-}"
  local period="${2:-5}"

  if [[ -z "$metric_name" ]]; then
    echo "0"
    return
  fi

  if ! [[ "$period" =~ ^[0-9]+$ ]] || [[ $period -lt 1 ]] || [[ $period -gt 100 ]]; then
    period=5
  fi

  metric_name=$(sanitize_metric_name "$metric_name")
  local data_file="${HISTORICAL_DATA_DIR}/${metric_name}.csv"

  if [[ ! -f "$data_file" ]] || [[ ! -r "$data_file" ]]; then
    echo "0"
    return
  fi

  local recent_values
  recent_values=$(tail -n "$period" "$data_file" 2>/dev/null | cut -d',' -f2)

  if [[ -z "$recent_values" ]]; then
    echo "0"
    return
  fi

  local sum=0
  local count=0

  while IFS= read -r value; do
    if [[ -n "$value" ]] && [[ "$value" =~ ^[0-9]+$ ]]; then
      sum=$((sum + value))
      count=$((count + 1))
    fi
  done <<< "$recent_values"

  if [[ $count -eq 0 ]]; then
    echo "0"
    return
  fi

  echo $((sum / count))
}

export -f sanitize_metric_name
export -f save_historical_point
export -f get_historical_trend
export -f get_historical_average

