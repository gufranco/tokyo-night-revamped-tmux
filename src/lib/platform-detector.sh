#!/usr/bin/env bash

declare -gA PLATFORM_CACHE

has_command() {
  local cmd="${1}"

  if [[ -n "${PLATFORM_CACHE[${cmd}]}" ]]; then
    return "${PLATFORM_CACHE[${cmd}]}"
  fi

  if command -v "${cmd}" &>/dev/null; then
    PLATFORM_CACHE["${cmd}"]=0
    return 0
  else
    PLATFORM_CACHE["${cmd}"]=1
    return 1
  fi
}

get_default_network_interface() {
  local os
  os="$(uname -s)"

  case "${os}" in
    Darwin*)
      route -n get default 2>/dev/null | awk '/interface:/ {print $2}' || echo "en0"
      ;;
    Linux*)
      if [[ -f /proc/net/route ]]; then
        awk '$2 == "00000000" {print $1; exit}' /proc/net/route 2>/dev/null || echo "eth0"
      else
        echo "eth0"
      fi
      ;;
    *)
      echo "eth0"
      ;;
  esac
}

get_cpu_count() {
  local os
  os="$(uname -s)"

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

get_total_memory_kb() {
  local os
  os="$(uname -s)"

  case "${os}" in
    Darwin*)
      local mem_bytes
      mem_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
      echo $(( mem_bytes / 1024 ))
      ;;
    Linux*)
      awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0"
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_active_memory_kb() {
  local os
  os="$(uname -s)"

  case "${os}" in
    Darwin*)
      local page_size active wired compressed
      page_size=$(pagesize 2>/dev/null || sysctl -n hw.pagesize 2>/dev/null || echo "4096")

      local vm_output
      vm_output=$(vm_stat 2>/dev/null)

      active=$(echo "${vm_output}" | awk '/Pages active:/ {print $NF}' | tr -d '.')
      wired=$(echo "${vm_output}" | awk '/Pages wired down:/ {print $NF}' | tr -d '.')
      compressed=$(echo "${vm_output}" | awk '/Pages occupied by compressor:/ {print $NF}' | tr -d '.')

      active=${active:-0}
      wired=${wired:-0}
      compressed=${compressed:-0}

      echo $(( (active + wired + compressed) * page_size / 1024 ))
      ;;
    Linux*)
      awk '
        /MemTotal:/ {total=$2}
        /MemAvailable:/ {available=$2}
        END {print total - available}
      ' /proc/meminfo 2>/dev/null || echo "0"
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_cpu_usage_percentage() {
  local os
  os="$(uname -s)"

  case "${os}" in
    Darwin*)
      local cpu_line cpu_user cpu_sys cpu_total
      cpu_line=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage")
      cpu_user=$(echo "$cpu_line" | awk '{print $3}' | sed 's/%//')
      cpu_sys=$(echo "$cpu_line" | awk '{print $5}' | sed 's/%//')

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
      frac_sum=$((cpu_user_frac + cpu_sys_frac))
      if [[ $frac_sum -ge 100 ]]; then
        cpu_total=$((cpu_total + frac_sum / 100))
        frac_sum=$((frac_sum % 100))
      fi
      if [[ $frac_sum -ge 50 ]]; then
        cpu_total=$((cpu_total + 1))
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
  os="$(uname -s)"

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

get_disk_usage() {
  local path="${1:-/}"

  if has_command df; then
    df -k "${path}" 2>/dev/null | awk 'NR==2 {
      used_gb = int($3 / 1048576)
      total_gb = int($2 / 1048576)
      if (total_gb > 0) {
        percent = int(($3 * 100) / $2)
      } else {
        percent = 0
      }
      print used_gb " " total_gb " " percent
    }' || echo "0 0 0"
  else
    echo "0 0 0"
  fi
}

get_gpu_usage_percentage() {
  local os
  os="$(uname -s)"

  case "${os}" in
    Darwin*)
      if [[ "$(uname -m)" == "arm64" ]]; then
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

get_cpu_temperature() {
  local os
  os="$(uname -s)"
  local temp=0

  case "${os}" in
    Darwin*)
      if has_command istats; then
        temp=$(istats cpu temp 2>/dev/null | awk '{print $3}' | sed 's/°C//' | head -1)
      elif has_command osx-cpu-temp; then
        temp=$(osx-cpu-temp 2>/dev/null | sed 's/°C//' | head -1)
      elif [[ -f /sys/devices/virtual/thermal/thermal_zone0/temp ]]; then
        temp=$(awk '{print int($1/1000)}' /sys/devices/virtual/thermal/thermal_zone0/temp 2>/dev/null)
      fi
      ;;
    Linux*)
      if [[ -d /sys/class/thermal ]]; then
        for thermal in /sys/class/thermal/thermal_zone*/temp; do
          if [[ -f "$thermal" ]]; then
            local zone_temp
            zone_temp=$(awk '{print int($1/1000)}' "$thermal" 2>/dev/null)
            if [[ -n "$zone_temp" ]] && [[ "$zone_temp" =~ ^[0-9]+$ ]] && [[ $zone_temp -gt $temp ]]; then
              temp=$zone_temp
            fi
          fi
        done
      fi

      if [[ $temp -eq 0 ]] && has_command sensors; then
        temp=$(sensors 2>/dev/null | awk '/Core 0|CPU Temperature|Tdie|Package id 0/ {gsub(/[^0-9.]/, "", $3); split($3, a, "."); print a[1]; exit}')
      fi
      ;;
  esac

  [[ -n "$temp" ]] && [[ "$temp" =~ ^[0-9]+$ ]] && echo "$temp" || echo "0"
}

get_gpu_temperature() {
  local os
  os="$(uname -s)"
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

get_system_uptime() {
  local os
  os="$(uname -s)"
  local uptime_seconds=0

  case "${os}" in
    Darwin*)
      uptime_seconds=$(sysctl -n kern.boottime 2>/dev/null | awk '{print $4}' | sed 's/,//')
      if [[ -n "$uptime_seconds" ]] && [[ "$uptime_seconds" =~ ^[0-9]+$ ]]; then
        current_time=$(date +%s)
        uptime_seconds=$(( current_time - uptime_seconds ))
      else
        uptime_seconds=0
      fi
      ;;
    Linux*)
      if [[ -f /proc/uptime ]]; then
        uptime_seconds=$(awk '{print int($1)}' /proc/uptime 2>/dev/null)
      fi
      ;;
  esac

  echo "${uptime_seconds:-0}"
}

format_uptime() {
  local seconds=$1
  local days=$(( seconds / 86400 ))
  local hours=$(( (seconds % 86400) / 3600 ))
  local minutes=$(( (seconds % 3600) / 60 ))

  if [[ $days -gt 0 ]]; then
    echo "${days}d ${hours}h ${minutes}m"
  elif [[ $hours -gt 0 ]]; then
    echo "${hours}h ${minutes}m"
  else
    echo "${minutes}m"
  fi
}

get_top_processes() {
  local count=${1:-3}
  local os
  os="$(uname -s)"
  local processes=""

  case "${os}" in
    Darwin*)
      processes=$(ps aux 2>/dev/null | sort -rk 3,3 | head -n $((count + 1)) | tail -n $count | awk '{printf "%s:%s ", $11, int($3)}')
      ;;
    Linux*)
      processes=$(ps aux 2>/dev/null | sort -rk 3,3 | head -n $((count + 1)) | tail -n $count | awk '{printf "%s:%s ", $11, int($3)}')
      ;;
  esac

  echo "$processes"
}

get_docker_containers() {
  if ! has_command docker; then
    echo "0"
    return
  fi

  docker ps -q 2>/dev/null | wc -l | tr -d ' '
}

get_kubernetes_pods() {
  if ! has_command kubectl; then
    echo "0"
    return
  fi

  kubectl get pods --all-namespaces --field-selector=status.phase=Running -o json 2>/dev/null | grep -c '"phase":"Running"' || echo "0"
}

get_disk_io() {
  local os
  os="$(uname -s)"
  local read_kb=0
  local write_kb=0

  case "${os}" in
    Darwin*)
      if has_command iostat; then
        read -r read_kb write_kb < <(iostat -d 1 2 | awk 'NR>3 && /^disk/ {r+=$3; w+=$4} END {print int(r), int(w)}')
      fi
      ;;
    Linux*)
      if [[ -f /proc/diskstats ]]; then
        read -r read_kb write_kb < <(awk '{r+=$6; w+=$10} END {print int(r/2), int(w/2)}' /proc/diskstats)
      fi
      ;;
  esac

  echo "${read_kb} ${write_kb}"
}

get_vpn_connection_name() {
  local os
  os="$(uname -s)"
  local vpn_name=""

  case "${os}" in
    Darwin*)
      if has_command scutil; then
        vpn_name=$(scutil --nc list 2>/dev/null | awk '/Connected/ {print $NF; exit}')
      fi
      ;;
    Linux*)
      if has_command nmcli; then
        vpn_name=$(nmcli connection show --active 2>/dev/null | awk '/vpn|VPN/ {print $1; exit}')
      elif [[ -d /sys/class/net ]]; then
        for iface in /sys/class/net/tun* /sys/class/net/wg* /sys/class/net/ppp*; do
          if [[ -d "$iface" ]]; then
            vpn_name=$(basename "$iface")
            break
          fi
        done
      fi
      ;;
  esac

  echo "$vpn_name"
}

get_wifi_signal_strength() {
  local os
  os="$(uname -s)"
  local signal=0

  case "${os}" in
    Darwin*)
      if has_command /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport; then
        signal=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk '/agrCtlRSSI/ {print $2}')
      elif has_command networksetup; then
        local wifi_interface
        wifi_interface=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|AirPort/ {getline; print $2}')
        if [[ -n "$wifi_interface" ]]; then
          signal=$(networksetup -getairportnetwork "$wifi_interface" 2>/dev/null | awk '{print $NF}')
        fi
      fi
      ;;
    Linux*)
      local wifi_interface
      wifi_interface=$(iwconfig 2>/dev/null | awk '/IEEE 802.11/ {print $1; exit}')
      if [[ -n "$wifi_interface" ]]; then
        signal=$(iwconfig "$wifi_interface" 2>/dev/null | awk -F'=' '/Signal level/ {gsub(/[^0-9-]/, "", $2); print $2}')
      elif [[ -f /proc/net/wireless ]]; then
        signal=$(awk 'NR>2 {print $4; exit}' /proc/net/wireless 2>/dev/null)
      fi
      ;;
  esac

  [[ -n "$signal" ]] && [[ "$signal" =~ ^-?[0-9]+$ ]] && echo "$signal" || echo "0"
}

get_network_connections() {
  local os
  os="$(uname -s)"
  local connections=0

  case "${os}" in
    Darwin*)
      if has_command netstat; then
        connections=$(netstat -an 2>/dev/null | grep -cE "^tcp[46]|^udp[46]" || echo "0")
      fi
      ;;
    Linux*)
      if [[ -f /proc/net/sockstat ]]; then
        connections=$(awk '/TCP:/ {print $3}' /proc/net/sockstat 2>/dev/null || echo "0")
      elif has_command ss; then
        connections=$(ss -tun 2>/dev/null | grep -cE "^ESTAB|^LISTEN" || echo "0")
      elif has_command netstat; then
        connections=$(netstat -tun 2>/dev/null | grep -cE "^tcp|^udp" || echo "0")
      fi
      ;;
  esac

  echo "${connections:-0}"
}

get_cpu_frequency() {
  local os
  os="$(uname -s)"
  local freq=0

  case "${os}" in
    Darwin*)
      if has_command sysctl; then
        freq=$(sysctl -n hw.cpufrequency 2>/dev/null)
        if [[ -n "$freq" ]] && [[ "$freq" =~ ^[0-9]+$ ]] && [[ $freq -gt 0 ]]; then
          freq=$(( freq / 1000000 ))
        else
          freq=0
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

  [[ -n "$freq" ]] && [[ "$freq" =~ ^[0-9]+$ ]] && echo "$freq" || echo "0"
}

get_disk_space_gb() {
  local path="${1:-/}"
  local os
  os="$(uname -s)"
  local total_gb=0
  local used_gb=0
  local free_gb=0

  case "${os}" in
    Darwin*)
      if has_command df; then
        read -r total_gb used_gb free_gb < <(df -g "$path" 2>/dev/null | awk 'NR==2 {print int($2), int($3), int($4)}')
      fi
      ;;
    Linux*)
      if has_command df; then
        read -r total_gb used_gb free_gb < <(df -BG "$path" 2>/dev/null | awk 'NR==2 {gsub(/G/, "", $2); gsub(/G/, "", $3); gsub(/G/, "", $4); print int($2), int($3), int($4)}')
      fi
      ;;
  esac

  echo "${total_gb:-0} ${used_gb:-0} ${free_gb:-0}"
}

get_multiple_disks() {
  local os
  os="$(uname -s)"
  local disks=""

  case "${os}" in
    Darwin*)
      if has_command df; then
        disks=$(df -h 2>/dev/null | awk 'NR>1 && $1 ~ /^\/dev\// && $9 !~ /^\/Volumes\// {print $1 ":" $9 ":" $5}')
      fi
      ;;
    Linux*)
      if has_command df; then
        disks=$(df -h 2>/dev/null | awk 'NR>1 && $1 ~ /^\/dev\// && $6 !~ /^\/boot/ && $6 !~ /^\/snap/ {print $1 ":" $6 ":" $5}')
      fi
      ;;
  esac

  echo "$disks"
}

get_memory_pressure() {
  local os
  os="$(uname -s)"
  local pressure=0

  case "${os}" in
    Darwin*)
      if has_command memory_pressure; then
        pressure=$(memory_pressure 2>/dev/null | awk '/System-wide memory free percentage:/ {print $5}' | sed 's/%//')
      elif has_command vm_stat; then
        local pages_free pages_active pages_inactive pages_wired pages_compressed
        local page_size mem_total

        page_size=$(pagesize 2>/dev/null || sysctl -n hw.pagesize 2>/dev/null || echo "4096")
        mem_total=$(sysctl -n hw.memsize 2>/dev/null || echo "0")

        local pages_free pages_active pages_inactive pages_wired pages_compressed
        read -r pages_free pages_active pages_inactive pages_wired pages_compressed < <(vm_stat 2>/dev/null | awk '
          /Pages free:/ {free=$NF; gsub(/\./, "", free)}
          /Pages active:/ {active=$NF; gsub(/\./, "", active)}
          /Pages inactive:/ {inactive=$NF; gsub(/\./, "", inactive)}
          /Pages wired down:/ {wired=$NF; gsub(/\./, "", wired)}
          /Pages occupied by compressor:/ {compressed=$NF; gsub(/\./, "", compressed)}
          END {print free, active, inactive, wired, compressed}
        ')

        if [[ -n "$mem_total" ]] && [[ $mem_total -gt 0 ]]; then
          local mem_free
          mem_free=$(( (pages_free + pages_inactive) * page_size ))
          pressure=$(( (mem_free * 100) / mem_total ))
        fi
      fi
      ;;
    Linux*)
      if [[ -f /proc/pressure/memory ]]; then
        pressure=$(awk '/some/ {gsub(/total=/, "", $3); split($3, a, ","); print int(a[1]*100); exit}' /proc/pressure/memory 2>/dev/null)
      elif [[ -f /proc/meminfo ]]; then
        local mem_available mem_total
        mem_available=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null)
        mem_total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)
        if [[ -n "$mem_available" ]] && [[ -n "$mem_total" ]] && [[ $mem_total -gt 0 ]]; then
          pressure=$(( (mem_available * 100) / mem_total ))
        fi
      fi
      ;;
  esac

  [[ -n "$pressure" ]] && [[ "$pressure" =~ ^[0-9]+$ ]] && echo "$pressure" || echo "0"
}

get_system_health_status() {
  local cpu_usage mem_usage disk_usage temp_cpu temp_gpu
  local health_status="ok"
  local issues=0

  cpu_usage=$(get_cpu_usage_percentage)
  mem_usage=$(get_active_memory_kb)
  local mem_total
  mem_total=$(get_total_memory_kb)
  if [[ -n "$mem_total" ]] && [[ $mem_total -gt 0 ]]; then
    mem_usage=$(( (mem_usage * 100) / mem_total ))
  else
    mem_usage=0
  fi

  disk_usage=$(df -h / 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5}')
  temp_cpu=$(get_cpu_temperature)
  temp_gpu=$(get_gpu_temperature)

  if (( cpu_usage >= 90 )) || (( mem_usage >= 90 )) || (( disk_usage >= 90 )) || (( temp_cpu >= 85 )) || (( temp_gpu >= 85 )); then
    health_status="critical"
    issues=$((issues + 1))
  elif (( cpu_usage >= 75 )) || (( mem_usage >= 75 )) || (( disk_usage >= 75 )) || (( temp_cpu >= 70 )) || (( temp_gpu >= 70 )); then
    health_status="warning"
    issues=$((issues + 1))
  fi

  echo "${health_status}|${issues}"
}

export -f has_command
export -f get_default_network_interface
export -f get_cpu_count
export -f get_total_memory_kb
export -f get_active_memory_kb
export -f get_cpu_usage_percentage
export -f get_load_average
export -f get_disk_usage
export -f get_gpu_usage_percentage
export -f get_cpu_temperature
export -f get_gpu_temperature
export -f get_system_uptime
export -f format_uptime
export -f get_top_processes
export -f get_docker_containers
export -f get_kubernetes_pods
export -f get_disk_io
export -f get_vpn_connection_name
export -f get_wifi_signal_strength
export -f get_network_connections
export -f get_cpu_frequency
export -f get_disk_space_gb
export -f get_memory_pressure
export -f get_system_health_status
export -f get_multiple_disks

