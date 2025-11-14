#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

source "${LIB_DIR}/coreutils-compat.sh"

readonly FORMAT_HIDE=""
readonly FORMAT_NONE="0123456789"
readonly FORMAT_DIGITAL="🯰🯱🯲🯳🯴🯵🯶🯷🯸🯹"
readonly FORMAT_FSQUARE="󰎡󰎤󰎧󰎪󰎭󰎱󰎳󰎶󰎹󰎼"
readonly FORMAT_HSQUARE="󰎣󰎦󰎩󰎬󰎮󰎰󰎵󰎸󰎻󰎾"
readonly FORMAT_DSQUARE="󰎢󰎥󰎨󰎫󰎲󰎯󰎴󰎷󰎺󰎽"
readonly FORMAT_ROMAN=" 󱂈󱂉󱂊󱂋󱂌󱂍󱂎󱂏󱂐"
readonly FORMAT_SUPER="⁰¹²³⁴⁵⁶⁷⁸⁹"
readonly FORMAT_SUB="₀₁₂₃₄₅₆₇₈₉"

get_format_string() {
  local format_name="${1}"
  
  case "${format_name}" in
    hide) echo "$FORMAT_HIDE" ;;
    none) echo "$FORMAT_NONE" ;;
    digital) echo "$FORMAT_DIGITAL" ;;
    fsquare) echo "$FORMAT_FSQUARE" ;;
    hsquare) echo "$FORMAT_HSQUARE" ;;
    dsquare) echo "$FORMAT_DSQUARE" ;;
    roman) echo "$FORMAT_ROMAN" ;;
    super) echo "$FORMAT_SUPER" ;;
    sub) echo "$FORMAT_SUB" ;;
    *) echo "$FORMAT_NONE" ;;
  esac
}

format_number() {
  local number="${1}"
  local format_type="${2}"
  local format_string
  
  format_string=$(get_format_string "$format_type")
  
  [[ "$format_type" == "hide" ]] && return
  
  if [[ "$format_type" == "roman" ]] && (( ${
    echo -n "$number "
    return
  fi
  
  local i digit
  for ((i = 0; i < ${
    digit=${number:i:1}
    echo -n "${format_string:digit:1} "
  done
}

main() {
  local id="${1}"
  local format="${2:-none}"
  
  format_number "$id" "$format"
}

main "$@"
