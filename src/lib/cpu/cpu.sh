#!/usr/bin/env bash

if [[ -z "${LIB_DIR:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  UTILS_DIR="${SCRIPT_DIR}/../utils"
else
  UTILS_DIR="${LIB_DIR}/utils"
fi

source "${UTILS_DIR}/has-command.sh"
source "${UTILS_DIR}/platform-cache.sh"

get_cpu_count() {
  local os
  os="$(get_os)"

  case "${os}" in
    Darwin*)
      sysctl -n hw.ncpu 2>/dev/null || echo "1"
      ;;
    Linux*)
      grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1"
      ;;
    *)
      echo "1"
      ;;
  esac
}

get_cpu_usage_percentage() {
  local os
  os="$(get_os)"

  case "${os}" in
    Darwin*)
      local cpu_user cpu_sys cpu_total
      if command -v iostat >/dev/null 2>&1; then
        local iostat_output
        iostat_output=$(iostat -w 1 -c 2 2>/dev/null | tail -1)
        cpu_user=$(echo "$iostat_output" | awk '{us=$(NF-5); printf "%.0f", us+0}')
        cpu_sys=$(echo "$iostat_output" | awk '{sy=$(NF-4); printf "%.0f", sy+0}')
        cpu_total=$((cpu_user + cpu_sys))
        [[ -z "$cpu_user" ]] && cpu_user=0
        [[ -z "$cpu_sys" ]] && cpu_sys=0
        [[ $cpu_total -lt 0 ]] && cpu_total=0
        [[ $cpu_total -gt 100 ]] && cpu_total=100
      else
        local cpu_line cpu_user cpu_sys
        cpu_line=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage")
        cpu_user=$(echo "$cpu_line" | awk '{print $3}' | sed 's/%//')
        cpu_sys=$(echo "$cpu_line" | awk '{print $5}' | sed 's/%//')

        local cpu_user_int cpu_sys_int cpu_user_frac cpu_sys_frac
        cpu_user_int=${cpu_user%%.*}
        cpu_sys_int=${cpu_sys%%.*}
        cpu_user_frac=${cpu_user#*.}
        cpu_sys_frac=${cpu_sys#*.}

        cpu_user_int=${cpu_user_int:-0}
        cpu_sys_int=${cpu_sys_int:-0}
        cpu_user_frac=${cpu_user_frac:-0}
        cpu_sys_frac=${cpu_sys_frac:-0}

        cpu_user_frac=${cpu_user_frac:0:2}
        cpu_sys_frac=${cpu_sys_frac:0:2}
        cpu_user_frac=${cpu_user_frac:-0}
        cpu_sys_frac=${cpu_sys_frac:-0}

        while [[ ${#cpu_user_frac} -lt 2 ]]; do cpu_user_frac="${cpu_user_frac}0"; done
        while [[ ${#cpu_sys_frac} -lt 2 ]]; do cpu_sys_frac="${cpu_sys_frac}0"; done

        cpu_total=$((cpu_user_int + cpu_sys_int))
        local frac_sum
        frac_sum=$((cpu_user_frac + cpu_sys_frac))
        if [[ $frac_sum -ge 100 ]]; then
          cpu_total=$((cpu_total + frac_sum / 100))
          frac_sum=$((frac_sum % 100))
        fi
        if [[ $frac_sum -ge 50 ]]; then
          cpu_total=$((cpu_total + 1))
        fi
      fi
      echo "$cpu_total"
      ;;
    Linux*)
      if [[ -f /proc/stat ]]; then
        awk '
          /^cpu / {
            idle=$5
            total=0
            for(i=2;i<=NF;i++) total+=$i
            if (total > 0) {
              usage = 100 * (total - idle) / total
              print int(usage)
            } else {
              print 0
            }
            exit
          }
        ' /proc/stat 2>/dev/null || echo "0"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_load_average() {
  local os
  os="$(get_os)"

  case "${os}" in
    Darwin*)
      sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}' || echo "0"
      ;;
    Linux*)
      if [[ -f /proc/loadavg ]]; then
        awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0"
      else
        echo "0"
      fi
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_cpu_temperature() {
  local os
  os="$(get_os)"
  local temp=0

  case "${os}" in
    Darwin*)
      local arch
      arch="$(get_arch)"

      if [[ "$arch" == "x86_64" ]]; then
        if has_command istats; then
          local istats_output
          istats_output=$(istats cpu temp 2>/dev/null)

          if [[ -n "$istats_output" ]]; then
            temp=$(echo "$istats_output" | grep -oE '[0-9]+\.[0-9]+' | head -1)
            if [[ -z "$temp" ]] || [[ "$temp" == "0.0" ]]; then
              temp=$(echo "$istats_output" | awk '/CPU temp/ {for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.?[0-9]*$/) {val=$i+0; if(val>0) {print int(val+0.5); exit}}}')
            fi
            if [[ -n "$temp" ]] && [[ "$temp" =~ ^[0-9]+\.?[0-9]*$ ]] && [[ $(echo "$temp" | awk '{printf "%.0f", $1}') -gt 0 ]]; then
              temp=$(echo "$temp" | awk '{printf "%.0f", $1}')
            else
              temp=0
            fi
          fi
        fi

        if [[ $temp -eq 0 ]] && has_command osx-cpu-temp; then
          local osx_temp
          osx_temp=$(osx-cpu-temp 2>/dev/null | sed 's/°C//' | grep -oE '[0-9]+\.?[0-9]*' | head -1)
          if [[ -n "$osx_temp" ]] && [[ "$osx_temp" =~ ^[0-9]+\.?[0-9]*$ ]] && [[ $(echo "$osx_temp" | awk '{printf "%.0f", $1}') -gt 0 ]]; then
            temp=$(echo "$osx_temp" | awk '{printf "%.0f", $1}')
          fi
        fi
      else
        if has_command osx-cpu-temp; then
          local osx_temp
          osx_temp=$(osx-cpu-temp 2>/dev/null | sed 's/°C//' | grep -oE '[0-9]+\.?[0-9]*' | head -1)
          if [[ -n "$osx_temp" ]] && [[ "$osx_temp" =~ ^[0-9]+\.?[0-9]*$ ]] && [[ $(echo "$osx_temp" | awk '{printf "%.0f", $1}') -gt 0 ]]; then
            temp=$(echo "$osx_temp" | awk '{printf "%.0f", $1}')
          fi
        fi

        if [[ $temp -eq 0 ]] && has_command istats; then
          local istats_output
          istats_output=$(istats cpu temp 2>/dev/null)
          if [[ -n "$istats_output" ]]; then
            temp=$(echo "$istats_output" | grep -oE '[0-9]+\.[0-9]+' | head -1)
            if [[ -n "$temp" ]] && [[ "$temp" != "0.0" ]] && [[ "$temp" =~ ^[0-9]+\.?[0-9]*$ ]] && [[ $(echo "$temp" | awk '{printf "%.0f", $1}') -gt 0 ]]; then
              temp=$(echo "$temp" | awk '{printf "%.0f", $1}')
            else
              temp=0
            fi
          fi
        fi
      fi
      ;;
    Linux*)
      if [[ -d /sys/class/thermal ]]; then
        for thermal in /sys/class/thermal/thermal_zone*/temp; do
          if [[ -f "$thermal" ]]; then
            local zone_type
            zone_type=$(cat "${thermal%temp}type" 2>/dev/null)
            if [[ "$zone_type" == *"cpu"* ]] || [[ "$zone_type" == *"x86"* ]] || [[ "$zone_type" == *"acpitz"* ]]; then
              local zone_temp
              zone_temp=$(awk '{print int($1/1000)}' "$thermal" 2>/dev/null)
              if [[ -n "$zone_temp" ]] && [[ "$zone_temp" =~ ^[0-9]+$ ]] && [[ $zone_temp -gt $temp ]]; then
                temp=$zone_temp
              fi
            fi
          fi
        done
      fi

      if [[ $temp -eq 0 ]] && [[ -d /sys/devices/platform/coretemp.0 ]]; then
        for hwmon in /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp*_input; do
          if [[ -f "$hwmon" ]]; then
            local core_temp
            core_temp=$(awk '{print int($1/1000)}' "$hwmon" 2>/dev/null)
            if [[ -n "$core_temp" ]] && [[ "$core_temp" =~ ^[0-9]+$ ]] && [[ $core_temp -gt $temp ]]; then
              temp=$core_temp
            fi
          fi
        done
      fi

      if [[ $temp -eq 0 ]] && has_command sensors; then
        temp=$(sensors 2>/dev/null | awk '/Core 0|CPU Temperature|Tdie|Package id 0|k10temp-pci/ {gsub(/[^0-9.]/, "", $3); split($3, a, "."); if (a[1] > 0) {print a[1]; exit}}')
      fi
      ;;
  esac

  [[ -n "$temp" ]] && [[ "$temp" =~ ^[0-9]+$ ]] && [[ $temp -gt 0 ]] && echo "$temp" || echo "0"
}

get_cpu_frequency() {
  local os
  os="$(get_os)"
  local freq=0

  case "${os}" in
    Darwin*)
      if has_command sysctl; then
        local arch
        arch="$(get_arch)"

        if [[ "$arch" == "arm64" ]]; then
          local brand_string
          brand_string=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "")

          if [[ -n "$brand_string" ]]; then
            local gen
            gen=$(echo "$brand_string" | grep -oE "M[1-5]" | grep -oE "[1-5]" | head -1)

            if [[ -n "$gen" ]] && [[ "$gen" =~ ^[1-5]$ ]]; then
              local cpu_freqs=(0 3200 3400 4000 4200 4500)
              freq="${cpu_freqs[$gen]}"
            fi
          fi
        else
          freq=$(sysctl -n hw.cpufrequency 2>/dev/null || echo "0")
          if [[ -n "$freq" ]] && [[ "$freq" =~ ^[0-9]+$ ]] && [[ $freq -gt 0 ]]; then
            freq=$(( freq / 1000000 ))
          else
            freq=0
          fi
        fi
      fi
      ;;
    Linux*)
      if [[ -f /proc/cpuinfo ]]; then
        freq=$(grep -m1 "cpu MHz" /proc/cpuinfo 2>/dev/null | awk '{print int($4)}')
      elif [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
        freq=$(awk '{print int($1/1000)}' /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
      fi
      ;;
  esac

  [[ -n "$freq" ]] && [[ "$freq" =~ ^[0-9]+$ ]] && [[ $freq -gt 0 ]] && echo "$freq" || echo "0"
}

get_cpu_frequency_current() {
  local os
  os="$(get_os)"
  local freq=0

  case "${os}" in
    Darwin*)
      local arch
      arch="$(get_arch)"

      if [[ "$arch" != "arm64" ]]; then
        freq=$(sysctl -n hw.cpufrequency 2>/dev/null || echo "0")
        if [[ -n "$freq" ]] && [[ "$freq" =~ ^[0-9]+$ ]] && [[ $freq -gt 0 ]]; then
          freq=$(( freq / 1000000 ))
        else
          freq=0
        fi
      fi
      ;;
    Linux*)
      if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
        freq=$(awk '{print int($1/1000)}' /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
      elif [[ -f /proc/cpuinfo ]]; then
        freq=$(grep -m1 "cpu MHz" /proc/cpuinfo 2>/dev/null | awk '{print int($4)}')
      fi
      ;;
  esac

  if [[ -n "$freq" ]] && [[ "$freq" =~ ^[0-9]+$ ]] && [[ $freq -gt 0 ]]; then
    echo "$freq"
    return
  fi

  local base_freq
  base_freq=$(get_cpu_frequency)

  if [[ -z "$base_freq" ]] || [[ "$base_freq" == "0" ]]; then
    echo "0"
    return
  fi

  local cpu_usage
  cpu_usage=$(get_cpu_usage_percentage)
  local cpu_temp
  cpu_temp=$(get_cpu_temperature)

  local estimated_freq=$base_freq

  if [[ -n "$cpu_usage" ]] && [[ "$cpu_usage" =~ ^[0-9]+$ ]]; then
    if [[ $cpu_usage -lt 5 ]]; then
      estimated_freq=$(( base_freq * 40 / 100 ))
    elif [[ $cpu_usage -lt 15 ]]; then
      estimated_freq=$(( base_freq * 55 / 100 ))
    elif [[ $cpu_usage -lt 30 ]]; then
      estimated_freq=$(( base_freq * 70 / 100 ))
    elif [[ $cpu_usage -lt 50 ]]; then
      estimated_freq=$(( base_freq * 85 / 100 ))
    elif [[ $cpu_usage -lt 70 ]]; then
      estimated_freq=$(( base_freq * 100 / 100 ))
    elif [[ $cpu_usage -lt 85 ]]; then
      estimated_freq=$(( base_freq * 110 / 100 ))
    else
      estimated_freq=$(( base_freq * 118 / 100 ))
    fi
  fi

  if [[ -n "$cpu_temp" ]] && [[ "$cpu_temp" =~ ^[0-9]+$ ]] && [[ $cpu_temp -gt 0 ]]; then
    if [[ $cpu_temp -ge 95 ]]; then
      estimated_freq=$(( estimated_freq * 65 / 100 ))
    elif [[ $cpu_temp -ge 85 ]]; then
      estimated_freq=$(( estimated_freq * 80 / 100 ))
    elif [[ $cpu_temp -ge 75 ]]; then
      estimated_freq=$(( estimated_freq * 90 / 100 ))
    fi
  fi

  [[ $estimated_freq -lt $(( base_freq * 35 / 100 )) ]] && estimated_freq=$(( base_freq * 35 / 100 ))
  [[ $estimated_freq -gt $(( base_freq * 120 / 100 )) ]] && estimated_freq=$(( base_freq * 120 / 100 ))

  echo "$estimated_freq"
}

export -f get_cpu_count
export -f get_cpu_usage_percentage
export -f get_load_average
export -f get_cpu_temperature
export -f get_cpu_frequency
export -f get_cpu_frequency_current

