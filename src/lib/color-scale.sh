#!/usr/bin/env bash
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Sistema de Cores e Escalas - Tokyo Night Revamped                   +
# Funções centralizadas para escalas de 4 níveis                       +
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# ==============================================================================
# Cores Base (vem do themes.sh, redefinimos aqui para clareza)
# ==============================================================================
COLOR_CYAN="#[fg=${THEME[cyan]},bg=default]"
COLOR_BLUE="#[fg=${THEME[blue]},bg=default]"
COLOR_YELLOW="#[fg=${THEME[yellow]},bg=default]"
COLOR_RED="#[fg=${THEME[red]},bg=default,bold]"
COLOR_GREEN="#[fg=${THEME[green]},bg=default]"
COLOR_RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# ==============================================================================
# Thresholds para Escalas de 4 Níveis
# ==============================================================================

# Sistema (CPU, GPU, Memória, Swap, Disco) - Percentual
readonly SYSTEM_NORMAL_MAX=49      # 0-49%: Cyan
readonly SYSTEM_MODERATE_MAX=74    # 50-74%: Blue
readonly SYSTEM_HIGH_MAX=89        # 75-89%: Yellow
# 90-100%: Red Bold

# Git - Arquivos Modificados
readonly GIT_CHANGES_NORMAL_MAX=5      # 1-5: Cyan
readonly GIT_CHANGES_MODERATE_MAX=15   # 6-15: Blue
readonly GIT_CHANGES_HIGH_MAX=30       # 16-30: Yellow
# 31+: Red Bold

# Git - Linhas (Insertions/Deletions)
readonly GIT_LINES_NORMAL_MAX=100      # 1-100: Cyan
readonly GIT_LINES_MODERATE_MAX=500    # 101-500: Blue
readonly GIT_LINES_HIGH_MAX=1000       # 501-1000: Yellow
# 1001+: Red Bold

# Git - Arquivos Não Rastreados
readonly GIT_UNTRACKED_NORMAL_MAX=3    # 1-3: Cyan
readonly GIT_UNTRACKED_HIGH_MAX=10     # 4-10: Yellow
# 11+: Red Bold (sem moderate)

# Git Web - Pull Requests
readonly GIT_PR_NORMAL_MAX=2           # 1-2: Green
readonly GIT_PR_MODERATE_MAX=4         # 3-4: Blue
# 5+: Yellow

# Git Web - Issues
readonly GIT_ISSUE_NORMAL_MAX=4        # 1-4: Green
readonly GIT_ISSUE_MODERATE_MAX=9      # 5-9: Blue
# 10+: Yellow

# Git Web - Reviews
readonly GIT_REVIEW_MODERATE_MAX=2     # 1-2: Yellow
# 3+: Red Bold

# Network - Velocidade (bytes por segundo)
readonly NET_SPEED_LOW_MAX=1048576         # 1MB/s: Cyan (lento)
readonly NET_SPEED_MODERATE_MAX=10485760   # 10MB/s: Blue (moderado)
readonly NET_SPEED_HIGH_MAX=52428800       # 50MB/s: Green (rápido)
# 50+MB/s: Yellow (muito rápido)

# Network - Ping (milissegundos)
readonly NET_PING_EXCELLENT_MAX=20     # < 20ms: Cyan (excelente)
readonly NET_PING_GOOD_MAX=50          # 20-50ms: Blue (bom)
readonly NET_PING_HIGH_MAX=100         # 50-100ms: Yellow (alto)
# 100+ms: Red (muito alto)

# ==============================================================================
# Função Genérica: Escala de 4 Níveis (Percentual)
# ==============================================================================
# Uso: get_percentage_color <valor> <max_normal> <max_moderate> <max_high>
# Retorna: cor apropriada baseada nos thresholds
# ==============================================================================
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

# ==============================================================================
# Função Genérica: Escala de 4 Níveis (Contagem)
# ==============================================================================
# Uso: get_count_color <valor> <max_normal> <max_moderate> <max_high>
# Retorna: cor apropriada baseada nos thresholds
# ==============================================================================
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

# ==============================================================================
# Funções Específicas: Sistema (CPU, GPU, Memória, Swap, Disco)
# ==============================================================================

get_system_color() {
  local percentage=$1
  get_percentage_color "$percentage" \
    "$SYSTEM_NORMAL_MAX" \
    "$SYSTEM_MODERATE_MAX" \
    "$SYSTEM_HIGH_MAX"
}

# ==============================================================================
# Funções Específicas: Git Local
# ==============================================================================

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
  
  # Apenas 3 níveis para untracked
  if (( count > GIT_UNTRACKED_HIGH_MAX )); then
    echo "${COLOR_RED}"
  elif (( count > GIT_UNTRACKED_NORMAL_MAX )); then
    echo "${COLOR_YELLOW}"
  else
    echo "${COLOR_CYAN}"
  fi
}

# ==============================================================================
# Funções Específicas: Git Web (GitHub/GitLab)
# ==============================================================================

get_git_pr_color() {
  local count=$1
  
  # 0 = cyan (limpo)
  [[ $count -eq 0 ]] && echo "${COLOR_CYAN}" && return
  
  # Escala progressiva para PRs
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
  
  # 0 = cyan (limpo)
  [[ $count -eq 0 ]] && echo "${COLOR_CYAN}" && return
  
  # Reviews são sempre urgentes
  if (( count >= 3 )); then
    echo "${COLOR_RED}"
  else
    echo "${COLOR_YELLOW}"
  fi
}

get_git_issue_color() {
  local count=$1
  
  # 0 = cyan (limpo)
  [[ $count -eq 0 ]] && echo "${COLOR_CYAN}" && return
  
  # Escala progressiva para issues
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
  
  # 0 = cyan (limpo), qualquer bug = red (urgente!)
  [[ $count -eq 0 ]] && echo "${COLOR_CYAN}" || echo "${COLOR_RED}"
}

# ==============================================================================
# Funções Específicas: Network (Velocidade e Ping)
# ==============================================================================

get_net_speed_color() {
  local bytes_per_sec=$1
  
  # Quanto maior a velocidade, melhor (mais verde/amarelo)
  if (( bytes_per_sec >= NET_SPEED_HIGH_MAX )); then
    echo "${COLOR_YELLOW}"  # Muito rápido!
  elif (( bytes_per_sec >= NET_SPEED_MODERATE_MAX )); then
    echo "${COLOR_GREEN}"   # Rápido
  elif (( bytes_per_sec >= NET_SPEED_LOW_MAX )); then
    echo "${COLOR_BLUE}"    # Moderado
  else
    echo "${COLOR_CYAN}"    # Lento
  fi
}

get_net_ping_color() {
  local ping_ms=$1
  
  # Quanto menor o ping, melhor
  if (( ping_ms >= 100 )); then
    echo "${COLOR_RED}"     # Muito alto
  elif (( ping_ms >= 50 )); then
    echo "${COLOR_YELLOW}"  # Alto
  elif (( ping_ms >= 20 )); then
    echo "${COLOR_BLUE}"    # Bom
  else
    echo "${COLOR_CYAN}"    # Excelente
  fi
}

# ==============================================================================
# Funções Específicas: Timezone Context (Horário Comercial)
# ==============================================================================

get_timezone_period_icon() {
  local hour=$1
  local is_weekend=$2  # 0=weekday, 1=weekend
  
  if [[ $is_weekend -eq 1 ]]; then
    echo "󰙵"  # Fim de semana
    return
  fi
  
  if (( hour >= 0 && hour < 7 )); then
    echo "󰖔"  # Madrugada profunda
  elif (( hour >= 7 && hour < 9 )); then
    echo "󰖜"  # Pré-expediente (sol nascendo)
  elif (( hour >= 9 && hour < 12 )); then
    echo "󰖙"  # Manhã produtiva
  elif (( hour >= 12 && hour < 14 )); then
    echo "󰖙"  # Meio-dia
  elif (( hour >= 14 && hour < 18 )); then
    echo "󰖙"  # Tarde produtiva
  elif (( hour >= 18 && hour < 20 )); then
    echo "󰖛"  # Fim do expediente (sol se pondo)
  elif (( hour >= 20 && hour < 23 )); then
    echo "󰖔"  # Noite
  else
    echo "󰖔"  # Madrugada
  fi
}

get_timezone_period_color() {
  local hour=$1
  local is_weekend=$2
  
  if [[ $is_weekend -eq 1 ]]; then
    echo "#[fg=${THEME[cyan]},bg=default,dim]"
    return
  fi
  
  if (( hour >= 0 && hour < 7 )); then
    echo "#[fg=${THEME[magenta]},bg=default,dim]"  # Dormindo
  elif (( hour >= 7 && hour < 9 )); then
    echo "#[fg=${THEME[cyan]},bg=default]"          # Chegando
  elif (( hour >= 9 && hour < 12 )); then
    echo "#[fg=${THEME[green]},bg=default]"         # Manhã produtiva
  elif (( hour >= 12 && hour < 14 )); then
    echo "#[fg=${THEME[yellow]},bg=default]"        # Meio-dia
  elif (( hour >= 14 && hour < 18 )); then
    echo "#[fg=${THEME[green]},bg=default]"         # Tarde produtiva
  elif (( hour >= 18 && hour < 20 )); then
    echo "#[fg=${THEME[blue]},bg=default]"          # Saindo
  elif (( hour >= 20 && hour < 23 )); then
    echo "#[fg=${THEME[magenta]},bg=default]"       # Noite
  else
    echo "#[fg=${THEME[magenta]},bg=default,dim]"   # Madrugada
  fi
}

# ==============================================================================
# Funções Utilitárias: Formatação
# ==============================================================================

# Formata ícone + valor + reset
# Uso: format_colored_value <cor> <icone> <valor> [unidade]
format_colored_value() {
  local color=$1
  local icon=$2
  local value=$3
  local unit=${4:-}
  
  echo "${color}${icon} ${value}${unit}${COLOR_RESET}"
}

# Formata apenas se valor > 0
# Uso: format_if_nonzero <cor> <icone> <valor> [unidade]
format_if_nonzero() {
  local color=$1
  local icon=$2
  local value=$3
  local unit=${4:-}
  
  [[ $value -gt 0 ]] && echo " $(format_colored_value "$color" "$icon" "$value" "$unit")"
}

# ==============================================================================
# Exportar Funções
# ==============================================================================

export -f get_percentage_color
export -f get_count_color
export -f get_system_color
export -f get_git_changes_color
export -f get_git_lines_color
export -f get_git_untracked_color
export -f get_git_pr_color
export -f get_git_review_color
export -f get_git_issue_color
export -f get_git_bug_color
export -f get_net_speed_color
export -f get_net_ping_color
export -f get_timezone_period_icon
export -f get_timezone_period_color
export -f format_colored_value
export -f format_if_nonzero

# Exportar cores
export COLOR_CYAN COLOR_BLUE COLOR_YELLOW COLOR_RED COLOR_GREEN COLOR_RESET

