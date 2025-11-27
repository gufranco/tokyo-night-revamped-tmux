#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."

source "${LIB_DIR}/tmux/tmux-config.sh"

get_custom_color() {
  local color_key="${1}"
  local default_value="${2}"
  local option_name="@tokyo-night-tmux_color_${color_key}"

  local custom_color
  custom_color=$(get_tmux_option "${option_name}" "")

  if [[ -n "${custom_color}" ]]; then
    echo "${custom_color}"
  else
    echo "${default_value}"
  fi
}

apply_custom_theme_colors() {
  THEME["background"]=$(get_custom_color "background" "${THEME[background]}")
  THEME["foreground"]=$(get_custom_color "foreground" "${THEME[foreground]}")
  THEME["black"]=$(get_custom_color "black" "${THEME[black]}")
  THEME["blue"]=$(get_custom_color "blue" "${THEME[blue]}")
  THEME["cyan"]=$(get_custom_color "cyan" "${THEME[cyan]}")
  THEME["green"]=$(get_custom_color "green" "${THEME[green]}")
  THEME["magenta"]=$(get_custom_color "magenta" "${THEME[magenta]}")
  THEME["red"]=$(get_custom_color "red" "${THEME[red]}")
  THEME["white"]=$(get_custom_color "white" "${THEME[white]}")
  THEME["yellow"]=$(get_custom_color "yellow" "${THEME[yellow]}")

  THEME["bblack"]=$(get_custom_color "bblack" "${THEME[bblack]}")
  THEME["bblue"]=$(get_custom_color "bblue" "${THEME[bblue]}")
  THEME["bcyan"]=$(get_custom_color "bcyan" "${THEME[bcyan]}")
  THEME["bgreen"]=$(get_custom_color "bgreen" "${THEME[bgreen]}")
  THEME["bmagenta"]=$(get_custom_color "bmagenta" "${THEME[bmagenta]}")
  THEME["bred"]=$(get_custom_color "bred" "${THEME[bred]}")
  THEME["bwhite"]=$(get_custom_color "bwhite" "${THEME[bwhite]}")
  THEME["byellow"]=$(get_custom_color "byellow" "${THEME[byellow]}")

  THEME["ghgreen"]=$(get_custom_color "ghgreen" "${THEME[ghgreen]}")
  THEME["ghmagenta"]=$(get_custom_color "ghmagenta" "${THEME[ghmagenta]}")
  THEME["ghred"]=$(get_custom_color "ghred" "${THEME[ghred]}")
  THEME["ghyellow"]=$(get_custom_color "ghyellow" "${THEME[ghyellow]}")
}

get_widget_color() {
  local widget_type="${1}"
  local color_type="${2}"
  local default_color="${3}"
  local option_name="@tokyo-night-tmux_color_${widget_type}_${color_type}"

  local custom_color
  custom_color=$(get_tmux_option "${option_name}" "")

  if [[ -n "${custom_color}" ]]; then
    echo "${custom_color}"
  else
    echo "${default_color}"
  fi
}

export -f get_custom_color
export -f apply_custom_theme_colors
export -f get_widget_color

