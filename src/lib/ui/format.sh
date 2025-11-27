#!/usr/bin/env bash

pad_percentage() {
  local value=$1
  local padded
  padded=$(printf "%-4s" "${value}%")
  printf "%s" "$padded"
}

pad_number() {
  local value=$1
  local suffix=$2
  local width=${3:-4}
  printf "%-${width}s" "${value}${suffix}"
}

pad_speed() {
  local speed=$1
  printf "%-8s" "$speed"
}

export -f pad_percentage
export -f pad_number
export -f pad_speed

