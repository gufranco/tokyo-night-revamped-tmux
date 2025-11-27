#!/usr/bin/env bash

TOOLTIP_CACHE_DIR="/tmp/tmux_tokyo_night_tooltips"
mkdir -p "$TOOLTIP_CACHE_DIR" 2>/dev/null

get_widget_tooltip() {
  local widget_name=$1
  local cache_file="${TOOLTIP_CACHE_DIR}/${widget_name}.tooltip"

  if [[ -f "$cache_file" ]]; then
    cat "$cache_file" 2>/dev/null
  fi
}

set_widget_tooltip() {
  local widget_name=$1
  local tooltip_text=$2
  local cache_file="${TOOLTIP_CACHE_DIR}/${widget_name}.tooltip"

  echo "$tooltip_text" > "$cache_file" 2>/dev/null
}

format_tooltip_for_tmux() {
  local tooltip_text=$1
  local max_length=80

  echo "$tooltip_text" | head -n 10 | while IFS= read -r line; do
    if [[ ${#line} -gt $max_length ]]; then
      echo "${line:0:$max_length}..."
    else
      echo "$line"
    fi
  done | tr '\n' ' ' | sed 's/ $//'
}

create_tooltip_widget() {
  local widget_name=$1
  local tooltip_text
  tooltip_text=$(get_widget_tooltip "$widget_name")

  if [[ -z "$tooltip_text" ]]; then
    echo ""
    return
  fi

  local formatted_tooltip
  formatted_tooltip=$(format_tooltip_for_tmux "$tooltip_text")

  echo "#{?mouse_any_flag,#[fg=cyan]#{=$1:tooltip_text},}"
}

generate_system_tooltip() {
  local tooltip="System Status:\n"

  if [[ "$(tmux show-option -gv @tokyo-night-tmux_show_system 2>/dev/null)" != "1" ]]; then
    tooltip="${tooltip}System widget: Disabled\n"
  else
    local cpu=$(tmux show-option -gv @tokyo-night-tmux_system_cpu 2>/dev/null)
    local gpu=$(tmux show-option -gv @tokyo-night-tmux_system_gpu 2>/dev/null)
    local mem=$(tmux show-option -gv @tokyo-night-tmux_system_memory 2>/dev/null)
    local disk=$(tmux show-option -gv @tokyo-night-tmux_system_disk 2>/dev/null)
    local battery=$(tmux show-option -gv @tokyo-night-tmux_system_battery 2>/dev/null)
    local temp=$(tmux show-option -gv @tokyo-night-tmux_system_temp 2>/dev/null)
    local uptime=$(tmux show-option -gv @tokyo-night-tmux_system_uptime 2>/dev/null)

    [[ "$cpu" != "1" ]] && tooltip="${tooltip}CPU: Disabled\n"
    [[ "$gpu" != "1" ]] && tooltip="${tooltip}GPU: Disabled\n"
    [[ "$mem" != "1" ]] && tooltip="${tooltip}Memory: Disabled\n"
    [[ "$disk" != "1" ]] && tooltip="${tooltip}Disk: Disabled\n"
    [[ "$battery" != "1" ]] && tooltip="${tooltip}Battery: Disabled\n"
    [[ "$temp" != "1" ]] && tooltip="${tooltip}Temperature: Disabled\n"
    [[ "$uptime" != "1" ]] && tooltip="${tooltip}Uptime: Disabled\n"
  fi

  echo -e "$tooltip"
}

generate_git_tooltip() {
  local tooltip="Git Status:\n"

  if [[ "$(tmux show-option -gv @tokyo-night-tmux_show_git 2>/dev/null)" != "1" ]]; then
    tooltip="${tooltip}Git widget: Disabled\n"
  else
    local web=$(tmux show-option -gv @tokyo-night-tmux_git_web 2>/dev/null)
    local stash=$(tmux show-option -gv @tokyo-night-tmux_git_stash 2>/dev/null)
    local ahead=$(tmux show-option -gv @tokyo-night-tmux_git_ahead_behind 2>/dev/null)

    [[ "$web" != "1" ]] && tooltip="${tooltip}Web features: Disabled\n"
    [[ "$stash" != "1" ]] && tooltip="${tooltip}Stash: Disabled\n"
    [[ "$ahead" != "1" ]] && tooltip="${tooltip}Ahead/Behind: Disabled\n"
  fi

  echo -e "$tooltip"
}

generate_network_tooltip() {
  local tooltip="Network Status:\n"

  if [[ "$(tmux show-option -gv @tokyo-night-tmux_show_netspeed 2>/dev/null)" != "1" ]]; then
    tooltip="${tooltip}Network widget: Disabled\n"
  else
    local ping=$(tmux show-option -gv @tokyo-night-tmux_netspeed_ping 2>/dev/null)
    local vpn=$(tmux show-option -gv @tokyo-night-tmux_netspeed_vpn 2>/dev/null)
    local wifi=$(tmux show-option -gv @tokyo-night-tmux_netspeed_wifi 2>/dev/null)

    [[ "$ping" != "1" ]] && tooltip="${tooltip}Ping: Disabled\n"
    [[ "$vpn" != "1" ]] && tooltip="${tooltip}VPN: Disabled\n"
    [[ "$wifi" != "1" ]] && tooltip="${tooltip}WiFi: Disabled\n"
  fi

  echo -e "$tooltip"
}

generate_context_tooltip() {
  local tooltip="Context Info:\n"

  if [[ "$(tmux show-option -gv @tokyo-night-tmux_show_context 2>/dev/null)" != "1" ]]; then
    tooltip="${tooltip}Context widget: Disabled\n"
  else
    local weather=$(tmux show-option -gv @tokyo-night-tmux_context_weather 2>/dev/null)

    [[ "$weather" != "1" ]] && tooltip="${tooltip}Weather: Disabled\n"
  fi

  echo -e "$tooltip"
}

export -f get_widget_tooltip
export -f set_widget_tooltip
export -f generate_system_tooltip
export -f generate_git_tooltip
export -f generate_network_tooltip
export -f generate_context_tooltip

