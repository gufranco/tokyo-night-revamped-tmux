#!/usr/bin/env bash

if [[ -z "${LIB_DIR:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  UTILS_DIR="${SCRIPT_DIR}/../utils"
else
  UTILS_DIR="${LIB_DIR}/utils"
fi

source "${UTILS_DIR}/has-command.sh"

get_gpu_usage_percentage() {
  local os
  os="$(get_os)"

  case "${os}" in
    Darwin*)
      if is_apple_silicon; then
        local gpu_usage
        gpu_usage=$(ioreg -r -d 1 -w 0 -c "IOAccelerator" 2>/dev/null | grep -o '"Device Utilization %"=[0-9]*' | sed 's/.*=//' | head -1)

        if [[ -z "$gpu_usage" ]] || [[ ! "$gpu_usage" =~ ^[0-9]+$ ]]; then
          local windowserver_cpu
          windowserver_cpu=$(ps axo %cpu,command 2>/dev/null | awk '/WindowServer/ && /-daemon/ {cpu=$1; gsub(/,/, ".", cpu); cpu_num=cpu+0; if (cpu_num > 0) print int(cpu_num); exit}')

          if [[ -n "$windowserver_cpu" ]] && [[ "$windowserver_cpu" =~ ^[0-9]+$ ]] && [[ $windowserver_cpu -gt 0 ]]; then
            if [[ $windowserver_cpu -le 3 ]]; then
              gpu_usage=$(( windowserver_cpu * 2 ))
            elif [[ $windowserver_cpu -le 10 ]]; then
              gpu_usage=$(( windowserver_cpu * 3 ))
            elif [[ $windowserver_cpu -le 25 ]]; then
              gpu_usage=$(( windowserver_cpu * 4 ))
            elif [[ $windowserver_cpu -le 40 ]]; then
              gpu_usage=$(( windowserver_cpu * 5 ))
            else
              gpu_usage=$(( windowserver_cpu * 6 ))
            fi
            (( gpu_usage > 100 )) && gpu_usage=100
            (( gpu_usage < 1 )) && gpu_usage=1
          else
            gpu_usage=1
          fi
        fi

        (( gpu_usage > 100 )) && gpu_usage=100
        (( gpu_usage < 1 )) && gpu_usage=1
        echo "$gpu_usage"
      else
        echo "0"
      fi
      ;;
    Linux*)
      local gpu_usage=0

      if has_command nvidia-smi; then
        gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
        if [[ -n "$gpu_usage" ]] && [[ "$gpu_usage" =~ ^[0-9]+$ ]]; then
          echo "$gpu_usage"
          return
        fi
      fi

      if has_command rocm-smi; then
        gpu_usage=$(rocm-smi --showuse --csv 2>/dev/null | awk -F',' 'NR==2 {gsub(/[^0-9]/, "", $2); print $2; exit}')
        if [[ -n "$gpu_usage" ]] && [[ "$gpu_usage" =~ ^[0-9]+$ ]]; then
          echo "$gpu_usage"
          return
        fi
      fi

      if has_command intel_gpu_top; then
        gpu_usage=$(timeout 1 intel_gpu_top -l 1 2>/dev/null | awk '/RC6/ {getline; if ($0 ~ /[0-9]+%/) {gsub(/[^0-9]/, "", $0); print; exit}}')
        if [[ -n "$gpu_usage" ]] && [[ "$gpu_usage" =~ ^[0-9]+$ ]]; then
          echo "$gpu_usage"
          return
        fi
      fi

      if [[ -d /sys/class/drm ]]; then
        for card in /sys/class/drm/card[0-9]*; do
          if [[ -d "${card}/device" ]]; then
            local cur_freq min_freq max_freq
            cur_freq=$(cat "${card}/gt_cur_freq_mhz" 2>/dev/null | head -1)
            min_freq=$(cat "${card}/gt_min_freq_mhz" 2>/dev/null | head -1)
            max_freq=$(cat "${card}/gt_max_freq_mhz" 2>/dev/null | head -1)

            if [[ -n "$cur_freq" ]] && [[ -n "$min_freq" ]] && [[ -n "$max_freq" ]] && \
              [[ "$cur_freq" =~ ^[0-9]+$ ]] && [[ "$min_freq" =~ ^[0-9]+$ ]] && [[ "$max_freq" =~ ^[0-9]+$ ]] && \
              [[ $max_freq -gt $min_freq ]] && [[ $cur_freq -ge $min_freq ]]; then
            local usage
              usage=$(( ((cur_freq - min_freq) * 100) / (max_freq - min_freq) ))
              (( usage > 100 )) && usage=100
              (( usage < 0 )) && usage=0
              if [[ $usage -gt 0 ]]; then
                echo "$usage"
                return
              fi
            fi
          fi
        done
      fi

      echo "0"
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_gpu_temperature() {
  local os
  os="$(get_os)"
  local temp=0

  case "${os}" in
    Darwin*)
      if has_command istats; then
        temp=$(istats gpu temp 2>/dev/null | awk '{print $3}' | sed 's/°C//' | head -1)
      fi
      ;;
    Linux*)
      if has_command nvidia-smi; then
        temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
      elif has_command rocm-smi; then
        temp=$(rocm-smi -t 2>/dev/null | awk '/Temperature/ {gsub(/[^0-9]/, "", $0); print; exit}')
      elif [[ -d /sys/class/drm ]]; then
        for card in /sys/class/drm/card[0-9]*; do
          if [[ -f "${card}/device/hwmon/hwmon*/temp1_input" ]]; then
            local gpu_temp
            gpu_temp=$(cat "${card}"/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1 | awk '{print int($1/1000)}')
            if [[ -n "$gpu_temp" ]] && [[ "$gpu_temp" =~ ^[0-9]+$ ]] && [[ $gpu_temp -gt $temp ]]; then
              temp=$gpu_temp
            fi
          fi
        done
      fi
      ;;
  esac

  [[ -n "$temp" ]] && [[ "$temp" =~ ^[0-9]+$ ]] && echo "$temp" || echo "0"
}

export -f get_gpu_usage_percentage
export -f get_gpu_temperature

