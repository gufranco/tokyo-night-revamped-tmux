#!/usr/bin/env bash

COLOR_CYAN="#[fg=${THEME[cyan]},bg=default]"
COLOR_BLUE="#[fg=${THEME[blue]},bg=default]"
COLOR_YELLOW="#[fg=${THEME[yellow]},bg=default]"
COLOR_RED="#[fg=${THEME[red]},bg=default,bold]"
COLOR_GREEN="#[fg=${THEME[green]},bg=default]"
COLOR_MAGENTA="#[fg=${THEME[magenta]},bg=default]"
COLOR_RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

readonly SYSTEM_NORMAL_MAX=49
readonly SYSTEM_MODERATE_MAX=74
readonly SYSTEM_HIGH_MAX=89

readonly LOAD_LOW_MULTIPLIER=50
readonly LOAD_MODERATE_MULTIPLIER=75
readonly LOAD_HIGH_MULTIPLIER=100

readonly GIT_CHANGES_NORMAL_MAX=5
readonly GIT_CHANGES_MODERATE_MAX=15
readonly GIT_CHANGES_HIGH_MAX=30

readonly GIT_LINES_NORMAL_MAX=100
readonly GIT_LINES_MODERATE_MAX=500
readonly GIT_LINES_HIGH_MAX=1000

readonly GIT_UNTRACKED_NORMAL_MAX=3
readonly GIT_UNTRACKED_HIGH_MAX=10

readonly GIT_PR_NORMAL_MAX=2
readonly GIT_PR_MODERATE_MAX=4

readonly GIT_ISSUE_NORMAL_MAX=4
readonly GIT_ISSUE_MODERATE_MAX=9

readonly GIT_REVIEW_MODERATE_MAX=2

readonly NET_SPEED_LOW_MAX=1048576
readonly NET_SPEED_MODERATE_MAX=10485760
readonly NET_SPEED_HIGH_MAX=52428800

readonly NET_PING_EXCELLENT_MAX=20
readonly NET_PING_GOOD_MAX=50
readonly NET_PING_HIGH_MAX=100

readonly TEMP_FREEZING_MAX=0
readonly TEMP_COLD_MAX=10
readonly TEMP_COOL_MAX=20
readonly TEMP_COMFORTABLE_MAX=25
readonly TEMP_HOT_MAX=30
get_percentage_color() {
  local value=$1
  local max_normal=${2:-49}
  local max_moderate=${3:-74}
  local max_high=${4:-89}

  if (( value >= 90 )); then
    echo "${COLOR_RED}"
  elif (( value > max_high )); then
    echo "${COLOR_YELLOW}"
  elif (( value > max_moderate )); then
    echo "${COLOR_BLUE}"
  else
    echo "${COLOR_CYAN}"
  fi
}

get_count_color() {
  local value=$1
  local max_normal=$2
  local max_moderate=$3
  local max_high=$4

  if (( value > max_high )); then
    echo "${COLOR_RED}"
  elif (( value > max_moderate )); then
    echo "${COLOR_YELLOW}"
  elif (( value > max_normal )); then
    echo "${COLOR_BLUE}"
  else
    echo "${COLOR_CYAN}"
  fi
}


get_system_color() {
  local percentage=$1
  get_percentage_color "$percentage" \
    "$SYSTEM_NORMAL_MAX" \
    "$SYSTEM_MODERATE_MAX" \
    "$SYSTEM_HIGH_MAX"
}

get_load_average_color() {
  local load=$1
  local cpu_count=$2

  if [[ -z "$load" ]] || [[ -z "$cpu_count" ]] || [[ "$cpu_count" -eq 0 ]]; then
    echo "${COLOR_CYAN}"
    return
  fi

  local load_int=$(echo "$load" | cut -d'.' -f1)
  local threshold_high=$((cpu_count * LOAD_HIGH_MULTIPLIER / 100))
  local threshold_moderate=$((cpu_count * LOAD_MODERATE_MULTIPLIER / 100))
  local threshold_low=$((cpu_count * LOAD_LOW_MULTIPLIER / 100))

  if (( load_int >= cpu_count )); then
    echo "${COLOR_RED}"
  elif (( load_int >= threshold_high )); then
    echo "${COLOR_YELLOW}"
  elif (( load_int >= threshold_moderate )); then
    echo "${COLOR_BLUE}"
  else
    echo "${COLOR_CYAN}"
  fi
}


get_git_changes_color() {
  local count=$1
  get_count_color "$count" \
    "$GIT_CHANGES_NORMAL_MAX" \
    "$GIT_CHANGES_MODERATE_MAX" \
    "$GIT_CHANGES_HIGH_MAX"
}

get_git_lines_color() {
  local count=$1
  get_count_color "$count" \
    "$GIT_LINES_NORMAL_MAX" \
    "$GIT_LINES_MODERATE_MAX" \
    "$GIT_LINES_HIGH_MAX"
}

get_git_untracked_color() {
  local count=$1

  if (( count > GIT_UNTRACKED_HIGH_MAX )); then
    echo "${COLOR_RED}"
  elif (( count > GIT_UNTRACKED_NORMAL_MAX )); then
    echo "${COLOR_YELLOW}"
  else
    echo "${COLOR_CYAN}"
  fi
}

get_git_pr_color() {
  local count=$1

  [[ $count -eq 0 ]] && echo "${COLOR_CYAN}" && return

  if (( count >= 5 )); then
    echo "${COLOR_YELLOW}"
  elif (( count >= 3 )); then
    echo "${COLOR_BLUE}"
  else
    echo "${COLOR_GREEN}"
  fi
}

get_git_review_color() {
  local count=$1

  [[ $count -eq 0 ]] && echo "${COLOR_CYAN}" && return

  if (( count >= 3 )); then
    echo "${COLOR_RED}"
  else
    echo "${COLOR_YELLOW}"
  fi
}

get_git_issue_color() {
  local count=$1

  [[ $count -eq 0 ]] && echo "${COLOR_CYAN}" && return

  if (( count >= 10 )); then
    echo "${COLOR_YELLOW}"
  elif (( count >= 5 )); then
    echo "${COLOR_BLUE}"
  else
    echo "${COLOR_GREEN}"
  fi
}

get_git_bug_color() {
  local count=$1

  [[ $count -eq 0 ]] && echo "${COLOR_CYAN}" || echo "${COLOR_RED}"
}

get_git_changes_icon() {
  local count=$1
  local idx=0

  if (( count > GIT_CHANGES_HIGH_MAX )); then
    idx=3
  elif (( count > GIT_CHANGES_MODERATE_MAX )); then
    idx=2
  elif (( count > GIT_CHANGES_NORMAL_MAX )); then
    idx=1
  fi

  echo "${GIT_CHANGES_ICONS[$idx]}"
}

get_git_insertions_icon() {
  local count=$1
  local idx=0

  if (( count > GIT_LINES_HIGH_MAX )); then
    idx=3
  elif (( count > GIT_LINES_MODERATE_MAX )); then
    idx=2
  elif (( count > GIT_LINES_NORMAL_MAX )); then
    idx=1
  fi

  echo "${GIT_INSERTIONS_ICONS[$idx]}"
}

get_git_deletions_icon() {
  local count=$1
  local idx=0

  if (( count > GIT_LINES_HIGH_MAX )); then
    idx=3
  elif (( count > GIT_LINES_MODERATE_MAX )); then
    idx=2
  elif (( count > GIT_LINES_NORMAL_MAX )); then
    idx=1
  fi

  echo "${GIT_DELETIONS_ICONS[$idx]}"
}

get_git_untracked_icon() {
  local count=$1
  local idx=0

  if (( count > GIT_UNTRACKED_HIGH_MAX )); then
    idx=2
  elif (( count > GIT_UNTRACKED_NORMAL_MAX )); then
    idx=1
  fi

  echo "${GIT_UNTRACKED_ICONS[$idx]}"
}

get_git_pr_icon() {
  local count=$1
  local idx=0

  if (( count >= 5 )); then
    idx=3
  elif (( count >= 3 )); then
    idx=2
  elif (( count >= 1 )); then
    idx=1
  fi

  echo "${GIT_PR_ICONS[$idx]}"
}

get_git_review_icon() {
  local count=$1
  local idx=0

  if (( count >= 3 )); then
    idx=2
  elif (( count >= 1 )); then
    idx=1
  fi

  echo "${GIT_REVIEW_ICONS[$idx]}"
}

get_git_issue_icon() {
  local count=$1
  local idx=0

  if (( count >= 10 )); then
    idx=3
  elif (( count >= 5 )); then
    idx=2
  elif (( count >= 1 )); then
    idx=1
  fi

  echo "${GIT_ISSUE_ICONS[$idx]}"
}

get_net_speed_color() {
  local bytes_per_sec=$1

  if (( bytes_per_sec >= NET_SPEED_HIGH_MAX )); then
    echo "${COLOR_YELLOW}"
  elif (( bytes_per_sec >= NET_SPEED_MODERATE_MAX )); then
    echo "${COLOR_GREEN}"
  elif (( bytes_per_sec >= NET_SPEED_LOW_MAX )); then
    echo "${COLOR_BLUE}"
  else
    echo "${COLOR_CYAN}"
  fi
}

get_net_ping_color() {
  local ping_ms=$1

  if (( ping_ms >= 100 )); then
    echo "${COLOR_RED}"
  elif (( ping_ms >= 50 )); then
    echo "${COLOR_YELLOW}"
  elif (( ping_ms >= 20 )); then
    echo "${COLOR_BLUE}"
  else
    echo "${COLOR_CYAN}"
  fi
}

get_temperature_color_and_icon() {
  local temp_str=$1
  local temp_num icon color

  temp_num=$(echo "$temp_str" | grep -oE '[-+]?[0-9]+' | head -1)

  [[ -z "$temp_num" ]] && echo "${COLOR_CYAN}󰖙" && return

  if (( temp_num < TEMP_FREEZING_MAX )); then
    icon="󰜗"
    color="#[fg=${THEME[magenta]},bg=default]"
  elif (( temp_num < TEMP_COLD_MAX )); then
    icon="󰖐"
    color="${COLOR_CYAN}"
  elif (( temp_num < TEMP_COOL_MAX )); then
    icon="󰖐"
    color="${COLOR_BLUE}"
  elif (( temp_num < TEMP_COMFORTABLE_MAX )); then
    icon="󰖙"
    color="${COLOR_GREEN}"
  elif (( temp_num < TEMP_HOT_MAX )); then
    icon="󰖙"
    color="${COLOR_YELLOW}"
  else
    icon="󰖙"
    color="${COLOR_RED}"
  fi

  echo "${color}${icon}"
}

get_timezone_period_icon() {
  local hour=$1
  local is_weekend=$2

  if [[ $is_weekend -eq 1 ]]; then
    echo "󰙵"
    return
  fi

  if (( hour >= 0 && hour < 7 )); then
    echo "󰖔"
  elif (( hour >= 7 && hour < 9 )); then
    echo "󰖜"
  elif (( hour >= 9 && hour < 12 )); then
    echo "󰖙"
  elif (( hour >= 12 && hour < 14 )); then
    echo "󰖙"
  elif (( hour >= 14 && hour < 18 )); then
    echo "󰖙"
  elif (( hour >= 18 && hour < 20 )); then
    echo "󰖛"
  elif (( hour >= 20 && hour < 23 )); then
    echo "󰖔"
  else
    echo "󰖔"
  fi
}

get_timezone_period_color() {
  local hour=$1
  local is_weekend=$2

  if [[ $is_weekend -eq 1 ]]; then
    echo "${COLOR_CYAN//bg=default/bg=default,dim}"
    return
  fi

  if (( hour >= 0 && hour < 7 )); then
    echo "${COLOR_MAGENTA//bg=default/bg=default,dim}"
  elif (( hour >= 7 && hour < 9 )); then
    echo "${COLOR_CYAN}"
  elif (( hour >= 9 && hour < 12 )); then
    echo "${COLOR_GREEN}"
  elif (( hour >= 12 && hour < 14 )); then
    echo "${COLOR_YELLOW}"
  elif (( hour >= 14 && hour < 18 )); then
    echo "${COLOR_GREEN}"
  elif (( hour >= 18 && hour < 20 )); then
    echo "${COLOR_BLUE}"
  elif (( hour >= 20 && hour < 23 )); then
    echo "${COLOR_MAGENTA}"
  else
    echo "${COLOR_MAGENTA//bg=default/bg=default,dim}"
  fi
}

format_colored_value() {
  local color=$1
  local icon=$2
  local value=$3
  local unit=${4:-}

  echo "${color}${icon} ${value}${unit}${COLOR_RESET}"
}

format_if_nonzero() {
  local color=$1
  local icon=$2
  local value=$3
  local unit=${4:-}

  [[ $value -gt 0 ]] && echo " $(format_colored_value "$color" "$icon" "$value" "$unit")"
}

export -f get_percentage_color
export -f get_count_color
export -f get_system_color
export -f get_load_average_color
export -f get_git_changes_color
export -f get_git_lines_color
export -f get_git_untracked_color
export -f get_git_pr_color
export -f get_git_review_color
export -f get_git_issue_color
export -f get_git_bug_color
export -f get_net_speed_color
export -f get_net_ping_color
export -f get_temperature_color_and_icon
export -f get_timezone_period_icon
export -f get_timezone_period_color
export -f format_colored_value
export -f format_if_nonzero
export -f get_git_changes_icon
export -f get_git_insertions_icon
export -f get_git_deletions_icon
export -f get_git_untracked_icon
export -f get_git_pr_icon
export -f get_git_review_icon
export -f get_git_issue_icon

export COLOR_CYAN COLOR_BLUE COLOR_YELLOW COLOR_RED COLOR_GREEN COLOR_MAGENTA COLOR_RESET

