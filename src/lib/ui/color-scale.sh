#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."

source "${LIB_DIR}/ui/color-config.sh"

get_color_cyan() {
  local color
  color=$(get_custom_color "widget_cyan" "${THEME[cyan]:-#7dcfff}")
  [[ -z "$color" ]] && echo "#7dcfff" || echo "$color"
}

get_color_blue() {
  local color
  color=$(get_custom_color "widget_blue" "${THEME[blue]:-#7aa2f7}")
  [[ -z "$color" ]] && echo "#7aa2f7" || echo "$color"
}

get_color_yellow() {
  local color
  color=$(get_custom_color "widget_yellow" "${THEME[yellow]:-#e0af68}")
  [[ -z "$color" ]] && echo "#e0af68" || echo "$color"
}

get_color_red() {
  local color
  color=$(get_custom_color "widget_red" "${THEME[red]:-#f7768e}")
  [[ -z "$color" ]] && echo "#f7768e" || echo "$color"
}

get_color_green() {
  local color
  color=$(get_custom_color "widget_green" "${THEME[green]:-#73daca}")
  [[ -z "$color" ]] && echo "#73daca" || echo "$color"
}

get_color_magenta() {
  local color
  color=$(get_custom_color "widget_magenta" "${THEME[magenta]:-#bb9af7}")
  [[ -z "$color" ]] && echo "#bb9af7" || echo "$color"
}

ensure_color_value() {
  local color_value="${1}"
  local fallback="${2}"

  if [[ -z "${color_value}" ]] || [[ "${color_value}" == "" ]]; then
    echo "${fallback}"
  else
    echo "${color_value}"
  fi
}

init_color_variables() {
  COLOR_CYAN="#[fg=$(get_color_cyan),bg=default]"
  COLOR_BLUE="#[fg=$(get_color_blue),bg=default]"
  COLOR_YELLOW="#[fg=$(get_color_yellow),bg=default]"
  COLOR_RED="#[fg=$(get_color_red),bg=default,bold]"
  COLOR_GREEN="#[fg=$(get_color_green),bg=default]"
  COLOR_MAGENTA="#[fg=$(get_color_magenta),bg=default]"
  COLOR_RESET="#[fg=${THEME[foreground]:-#a9b1d6},bg=${THEME[background]:-#1A1B26},nobold,noitalics,nounderscore,nodim]"
}

init_color_variables

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
    echo "${COLOR_BLUE}"
  elif (( value > max_normal )); then
    echo "${COLOR_YELLOW}"
  else
    echo "${COLOR_CYAN}"
  fi
}


get_system_color() {
  local percentage=$1
  local color_normal
  local color_moderate
  local color_high
  local color_critical

  local default_cyan default_blue default_yellow default_red

  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")
  default_blue=$(get_color_blue 2>/dev/null || echo "#7aa2f7")
  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")
  default_red=$(get_color_red 2>/dev/null || echo "#f7768e")

  color_normal=$(get_widget_color "system" "normal" "$default_cyan")
  color_moderate=$(get_widget_color "system" "moderate" "$default_blue")
  color_high=$(get_widget_color "system" "high" "$default_yellow")
  color_critical=$(get_widget_color "system" "critical" "$default_red")

  color_normal="${color_normal:-$default_cyan}"
  color_moderate="${color_moderate:-$default_blue}"
  color_high="${color_high:-$default_yellow}"
  color_critical="${color_critical:-$default_red}"

  if (( percentage >= 90 )); then
    echo "#[fg=${color_critical},bg=default,bold]"
  elif (( percentage > SYSTEM_HIGH_MAX )); then
    echo "#[fg=${color_high},bg=default]"
  elif (( percentage > SYSTEM_MODERATE_MAX )); then
    echo "#[fg=${color_moderate},bg=default]"
  else
    echo "#[fg=${color_normal},bg=default]"
  fi
}

get_load_average_color() {
  local load=$1
  local cpu_count=$2
  local color_low
  local color_moderate
  local color_high
  local color_critical

  local default_cyan default_blue default_yellow default_red

  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")
  default_blue=$(get_color_blue 2>/dev/null || echo "#7aa2f7")
  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")
  default_red=$(get_color_red 2>/dev/null || echo "#f7768e")

  color_low=$(get_widget_color "system" "load_low" "$default_cyan")
  color_moderate=$(get_widget_color "system" "load_moderate" "$default_blue")
  color_high=$(get_widget_color "system" "load_high" "$default_yellow")
  color_critical=$(get_widget_color "system" "load_critical" "$default_red")

  color_low="${color_low:-$default_cyan}"
  color_moderate="${color_moderate:-$default_blue}"
  color_high="${color_high:-$default_yellow}"
  color_critical="${color_critical:-$default_red}"

  if [[ -z "$load" ]] || [[ -z "$cpu_count" ]] || [[ "$cpu_count" -eq 0 ]]; then
    echo "#[fg=${color_low},bg=default]"
    return
  fi

  local load_int=$(echo "$load" | cut -d'.' -f1)
  local threshold_high=$((cpu_count * LOAD_HIGH_MULTIPLIER / 100))
  local threshold_moderate=$((cpu_count * LOAD_MODERATE_MULTIPLIER / 100))
  local threshold_low=$((cpu_count * LOAD_LOW_MULTIPLIER / 100))

  if (( load_int >= cpu_count )); then
    echo "#[fg=${color_critical},bg=default,bold]"
  elif (( load_int >= threshold_high )); then
    echo "#[fg=${color_high},bg=default]"
  elif (( load_int >= threshold_moderate )); then
    echo "#[fg=${color_moderate},bg=default]"
  else
    echo "#[fg=${color_low},bg=default]"
  fi
}


get_git_changes_color() {
  local count=$1
  local color_normal
  local color_moderate
  local color_high
  local color_critical

  local default_cyan default_blue default_yellow default_red

  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")
  default_blue=$(get_color_blue 2>/dev/null || echo "#7aa2f7")
  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")
  default_red=$(get_color_red 2>/dev/null || echo "#f7768e")

  color_normal=$(get_widget_color "git" "changes_normal" "$default_cyan")
  color_moderate=$(get_widget_color "git" "changes_moderate" "$default_blue")
  color_high=$(get_widget_color "git" "changes_high" "$default_yellow")
  color_critical=$(get_widget_color "git" "changes_critical" "$default_red")

  color_normal="${color_normal:-$default_cyan}"
  color_moderate="${color_moderate:-$default_blue}"
  color_high="${color_high:-$default_yellow}"
  color_critical="${color_critical:-$default_red}"

  if (( count > GIT_CHANGES_HIGH_MAX )); then
    echo "#[fg=${color_critical},bg=default]"
  elif (( count > GIT_CHANGES_MODERATE_MAX )); then
    echo "#[fg=${color_high},bg=default]"
  elif (( count > GIT_CHANGES_NORMAL_MAX )); then
    echo "#[fg=${color_moderate},bg=default]"
  else
    echo "#[fg=${color_normal},bg=default]"
  fi
}

get_git_lines_color() {
  local count=$1
  local color_normal
  local color_moderate
  local color_high
  local color_critical

  local default_cyan default_blue default_yellow default_red

  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")
  default_blue=$(get_color_blue 2>/dev/null || echo "#7aa2f7")
  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")
  default_red=$(get_color_red 2>/dev/null || echo "#f7768e")

  color_normal=$(get_widget_color "git" "lines_normal" "$default_cyan")
  color_moderate=$(get_widget_color "git" "lines_moderate" "$default_blue")
  color_high=$(get_widget_color "git" "lines_high" "$default_yellow")
  color_critical=$(get_widget_color "git" "lines_critical" "$default_red")

  color_normal="${color_normal:-$default_cyan}"
  color_moderate="${color_moderate:-$default_blue}"
  color_high="${color_high:-$default_yellow}"
  color_critical="${color_critical:-$default_red}"

  if (( count > GIT_LINES_HIGH_MAX )); then
    echo "#[fg=${color_critical},bg=default]"
  elif (( count > GIT_LINES_MODERATE_MAX )); then
    echo "#[fg=${color_high},bg=default]"
  elif (( count > GIT_LINES_NORMAL_MAX )); then
    echo "#[fg=${color_moderate},bg=default]"
  else
    echo "#[fg=${color_normal},bg=default]"
  fi
}

get_git_untracked_color() {
  local count=$1
  local color_normal
  local color_high
  local color_critical

  local default_cyan default_yellow default_red

  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")
  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")
  default_red=$(get_color_red 2>/dev/null || echo "#f7768e")

  color_normal=$(get_widget_color "git" "untracked_normal" "$default_cyan")
  color_high=$(get_widget_color "git" "untracked_high" "$default_yellow")
  color_critical=$(get_widget_color "git" "untracked_critical" "$default_red")

  color_normal="${color_normal:-$default_cyan}"
  color_high="${color_high:-$default_yellow}"
  color_critical="${color_critical:-$default_red}"

  if (( count > GIT_UNTRACKED_HIGH_MAX )); then
    echo "#[fg=${color_critical},bg=default]"
  elif (( count > GIT_UNTRACKED_NORMAL_MAX )); then
    echo "#[fg=${color_high},bg=default]"
  else
    echo "#[fg=${color_normal},bg=default]"
  fi
}

get_git_pr_color() {
  local count=$1
  local color_low
  local color_medium
  local color_high

  local default_green default_blue default_yellow default_cyan

  default_green=$(get_color_green 2>/dev/null || echo "#73daca")
  default_blue=$(get_color_blue 2>/dev/null || echo "#7aa2f7")
  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")
  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")

  color_low=$(get_widget_color "git" "pr_low" "$default_green")
  color_medium=$(get_widget_color "git" "pr_medium" "$default_blue")
  color_high=$(get_widget_color "git" "pr_high" "$default_yellow")

  color_low="${color_low:-$default_green}"
  color_medium="${color_medium:-$default_blue}"
  color_high="${color_high:-$default_yellow}"

  [[ $count -eq 0 ]] && echo "#[fg=$default_cyan,bg=default]" && return

  if (( count >= 5 )); then
    echo "#[fg=${color_high},bg=default]"
  elif (( count >= 3 )); then
    echo "#[fg=${color_medium},bg=default]"
  else
    echo "#[fg=${color_low},bg=default]"
  fi
}

get_git_review_color() {
  local count=$1
  local color_low
  local color_high

  local default_yellow default_red default_cyan

  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")
  default_red=$(get_color_red 2>/dev/null || echo "#f7768e")
  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")

  color_low=$(get_widget_color "git" "review_low" "$default_yellow")
  color_high=$(get_widget_color "git" "review_high" "$default_red")

  color_low="${color_low:-$default_yellow}"
  color_high="${color_high:-$default_red}"

  [[ $count -eq 0 ]] && echo "#[fg=$default_cyan,bg=default]" && return

  if (( count >= 3 )); then
    echo "#[fg=${color_high},bg=default]"
  else
    echo "#[fg=${color_low},bg=default]"
  fi
}

get_git_issue_color() {
  local count=$1
  local color_low
  local color_medium
  local color_high

  local default_green default_blue default_yellow default_cyan

  default_green=$(get_color_green 2>/dev/null || echo "#73daca")
  default_blue=$(get_color_blue 2>/dev/null || echo "#7aa2f7")
  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")
  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")

  color_low=$(get_widget_color "git" "issue_low" "$default_green")
  color_medium=$(get_widget_color "git" "issue_medium" "$default_blue")
  color_high=$(get_widget_color "git" "issue_high" "$default_yellow")

  color_low="${color_low:-$default_green}"
  color_medium="${color_medium:-$default_blue}"
  color_high="${color_high:-$default_yellow}"

  [[ $count -eq 0 ]] && echo "#[fg=$default_cyan,bg=default]" && return

  if (( count >= 10 )); then
    echo "#[fg=${color_high},bg=default]"
  elif (( count >= 5 )); then
    echo "#[fg=${color_medium},bg=default]"
  else
    echo "#[fg=${color_low},bg=default]"
  fi
}

get_git_bug_color() {
  local count=$1
  local color_normal
  local color_critical

  local default_cyan default_red

  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")
  default_red=$(get_color_red 2>/dev/null || echo "#f7768e")

  color_normal=$(get_widget_color "git" "bug_normal" "$default_cyan")
  color_critical=$(get_widget_color "git" "bug_critical" "$default_red")

  color_normal="${color_normal:-$default_cyan}"
  color_critical="${color_critical:-$default_red}"

  [[ $count -eq 0 ]] && echo "#[fg=${color_normal},bg=default]" || echo "#[fg=${color_critical},bg=default]"
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
    idx=2
  elif (( count >= 3 )); then
    idx=1
  fi

  echo "${GIT_PR_ICONS[$idx]}"
}

get_git_review_icon() {
  local count=$1
  local idx=0

  if (( count >= 3 )); then
    idx=1
  fi

  echo "${GIT_REVIEW_ICONS[$idx]}"
}

get_git_issue_icon() {
  local count=$1
  local idx=0

  if (( count >= 10 )); then
    idx=2
  elif (( count >= 5 )); then
    idx=1
  fi

  echo "${GIT_ISSUE_ICONS[$idx]}"
}

get_net_speed_color() {
  local bytes_per_sec=$1
  local color_low
  local color_medium
  local color_high
  local color_very_high

  local default_cyan default_blue default_green default_yellow

  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")
  default_blue=$(get_color_blue 2>/dev/null || echo "#7aa2f7")
  default_green=$(get_color_green 2>/dev/null || echo "#73daca")
  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")

  color_low=$(get_widget_color "network" "speed_low" "$default_cyan")
  color_medium=$(get_widget_color "network" "speed_medium" "$default_blue")
  color_high=$(get_widget_color "network" "speed_high" "$default_green")
  color_very_high=$(get_widget_color "network" "speed_very_high" "$default_yellow")

  color_low="${color_low:-$default_cyan}"
  color_medium="${color_medium:-$default_blue}"
  color_high="${color_high:-$default_green}"
  color_very_high="${color_very_high:-$default_yellow}"

  if (( bytes_per_sec >= NET_SPEED_HIGH_MAX )); then
    echo "#[fg=${color_very_high},bg=default]"
  elif (( bytes_per_sec >= NET_SPEED_MODERATE_MAX )); then
    echo "#[fg=${color_high},bg=default]"
  elif (( bytes_per_sec >= NET_SPEED_LOW_MAX )); then
    echo "#[fg=${color_medium},bg=default]"
  else
    echo "#[fg=${color_low},bg=default]"
  fi
}

get_net_ping_color() {
  local ping_ms=$1
  local color_excellent
  local color_good
  local color_high
  local color_very_high

  local default_cyan default_blue default_yellow default_red

  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")
  default_blue=$(get_color_blue 2>/dev/null || echo "#7aa2f7")
  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")
  default_red=$(get_color_red 2>/dev/null || echo "#f7768e")

  color_excellent=$(get_widget_color "network" "ping_excellent" "$default_cyan")
  color_good=$(get_widget_color "network" "ping_good" "$default_blue")
  color_high=$(get_widget_color "network" "ping_high" "$default_yellow")
  color_very_high=$(get_widget_color "network" "ping_very_high" "$default_red")

  color_excellent="${color_excellent:-$default_cyan}"
  color_good="${color_good:-$default_blue}"
  color_high="${color_high:-$default_yellow}"
  color_very_high="${color_very_high:-$default_red}"

  if (( ping_ms >= 100 )); then
    echo "#[fg=${color_very_high},bg=default]"
  elif (( ping_ms >= 50 )); then
    echo "#[fg=${color_high},bg=default]"
  elif (( ping_ms >= 20 )); then
    echo "#[fg=${color_good},bg=default]"
  else
    echo "#[fg=${color_excellent},bg=default]"
  fi
}

get_temperature_color_and_icon() {
  local temp_str=$1
  local temp_num icon color
  local color_freezing
  local color_cold
  local color_cool
  local color_comfortable
  local color_hot
  local color_very_hot

  local default_magenta default_cyan default_blue default_green default_yellow default_red

  default_magenta=$(get_color_magenta 2>/dev/null || echo "#bb9af7")
  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")
  default_blue=$(get_color_blue 2>/dev/null || echo "#7aa2f7")
  default_green=$(get_color_green 2>/dev/null || echo "#73daca")
  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")
  default_red=$(get_color_red 2>/dev/null || echo "#f7768e")

  temp_num=$(echo "$temp_str" | grep -oE '[-+]?[0-9]+' | head -1)

  color_freezing=$(get_widget_color "temperature" "freezing" "$default_magenta")
  color_cold=$(get_widget_color "temperature" "cold" "$default_cyan")
  color_cool=$(get_widget_color "temperature" "cool" "$default_blue")
  color_comfortable=$(get_widget_color "temperature" "comfortable" "$default_green")
  color_hot=$(get_widget_color "temperature" "hot" "$default_yellow")
  color_very_hot=$(get_widget_color "temperature" "very_hot" "$default_red")

  color_freezing="${color_freezing:-$default_magenta}"
  color_cold="${color_cold:-$default_cyan}"
  color_cool="${color_cool:-$default_blue}"
  color_comfortable="${color_comfortable:-$default_green}"
  color_hot="${color_hot:-$default_yellow}"
  color_very_hot="${color_very_hot:-$default_red}"

  if [[ -z "$temp_num" ]]; then
    echo "#[fg=${color_cold},bg=default]󰖙"
    return
  fi

  if (( temp_num <= TEMP_FREEZING_MAX )); then
    icon="󰜗"
    color="#[fg=${color_freezing},bg=default]"
  elif (( temp_num <= TEMP_COLD_MAX )); then
    icon="󰖐"
    color="#[fg=${color_cold},bg=default]"
  elif (( temp_num <= TEMP_COOL_MAX )); then
    icon="󰖐"
    color="#[fg=${color_cool},bg=default]"
  elif (( temp_num <= TEMP_COMFORTABLE_MAX )); then
    icon="󰖙"
    color="#[fg=${color_comfortable},bg=default]"
  elif (( temp_num <= TEMP_HOT_MAX )); then
    icon="󰖙"
    color="#[fg=${color_hot},bg=default]"
  else
    icon="󰖙"
    color="#[fg=${color_very_hot},bg=default]"
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
  local color_weekend
  local color_night
  local color_morning
  local color_day
  local color_afternoon
  local color_evening

  local default_cyan default_magenta default_green default_yellow default_blue

  default_cyan=$(get_color_cyan 2>/dev/null || echo "#7dcfff")
  default_magenta=$(get_color_magenta 2>/dev/null || echo "#bb9af7")
  default_green=$(get_color_green 2>/dev/null || echo "#73daca")
  default_yellow=$(get_color_yellow 2>/dev/null || echo "#e0af68")
  default_blue=$(get_color_blue 2>/dev/null || echo "#7aa2f7")

  color_weekend=$(get_widget_color "timezone" "weekend" "$default_cyan")
  color_night=$(get_widget_color "timezone" "night" "$default_magenta")
  color_morning=$(get_widget_color "timezone" "morning" "$default_cyan")
  color_day=$(get_widget_color "timezone" "day" "$default_green")
  color_afternoon=$(get_widget_color "timezone" "afternoon" "$default_yellow")
  color_evening=$(get_widget_color "timezone" "evening" "$default_blue")

  color_weekend="${color_weekend:-$default_cyan}"
  color_night="${color_night:-$default_magenta}"
  color_morning="${color_morning:-$default_cyan}"
  color_day="${color_day:-$default_green}"
  color_afternoon="${color_afternoon:-$default_yellow}"
  color_evening="${color_evening:-$default_blue}"

  if [[ $is_weekend -eq 1 ]]; then
    echo "#[fg=${color_weekend},bg=default]"
    return
  fi

  if (( hour >= 22 || hour < 5 )); then
    echo "#[fg=${color_night},bg=default]"
  elif (( hour >= 5 && hour < 12 )); then
    echo "#[fg=${color_morning},bg=default]"
  elif (( hour >= 12 && hour < 18 )); then
    echo "#[fg=${color_day},bg=default]"
  else
    echo "#[fg=${color_evening},bg=default]"
  fi
}

format_colored_value() {
  local color=$1
  local icon=$2
  local value=$3
  local unit=${4:-}
  echo "${color}${icon} ${value}${unit}"
}

format_if_nonzero() {
  local color=$1
  local icon=$2
  local value=$3
  local unit=${4:-}

  [[ $value -gt 0 ]] && echo " $(format_colored_value "$color" "$icon" "$value" "$unit")"
}

export -f get_color_cyan
export -f get_color_blue
export -f get_color_yellow
export -f get_color_red
export -f get_color_green
export -f get_color_magenta
export -f init_color_variables
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
