#!/usr/bin/env bash
# Swirl status bar — i3bar protocol with clickable Wi‑Fi (opens networkmanager-dmenu).
# Plain-text status cannot handle clicks; JSON blocks can.
set -euo pipefail

echo '{"version":1,"click_events":true}'
echo '['
echo '[]'

# Clicks arrive on stdin as JSON objects (leading comma after the first).
(
  while IFS= read -r line; do
    [[ -z "${line}" || "${line}" == "[" ]] && continue
    payload="${line#,}"
    name="$(printf '%s' "${payload}" | jq -r '.name // empty' 2>/dev/null || true)"
    button="$(printf '%s' "${payload}" | jq -r '.button // 0' 2>/dev/null || true)"
    case "${name}" in
      wifi)
        if [[ "${button}" == "1" ]]; then
          networkmanager_dmenu >/dev/null 2>&1 &
        fi
        ;;
    esac
  done
) &

prev_total=0
prev_idle=0

while true; do
  cpu_line=$(grep 'cpu ' /proc/stat)
  # shellcheck disable=SC2206
  cpu_values=(${cpu_line})
  user=${cpu_values[1]}
  nice=${cpu_values[2]}
  system=${cpu_values[3]}
  idle=${cpu_values[4]}
  iowait=${cpu_values[5]}
  irq=${cpu_values[6]}
  softirq=${cpu_values[7]}
  steal=${cpu_values[8]:-0}

  total=$((user + nice + system + idle + iowait + irq + softirq + steal))

  if [[ "${prev_total}" -gt 0 ]]; then
    total_diff=$((total - prev_total))
    idle_diff=$((idle - prev_idle))
    if [[ "${total_diff}" -gt 0 ]]; then
      cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))
    else
      cpu_usage=0
    fi
  else
    cpu_usage=0
  fi

  prev_total=$total
  prev_idle=$idle

  ram_usage=$(free -m | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')
  disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

  brightness_display="BRT:off"
  for bl in /sys/class/backlight/*; do
    [[ -d "${bl}" ]] || continue
    max_brightness=$(cat "${bl}/max_brightness" 2>/dev/null) || continue
    current_brightness=$(cat "${bl}/brightness" 2>/dev/null) || continue
    if [[ -n "${max_brightness}" && "${max_brightness}" -gt 0 ]]; then
      brightness=$((current_brightness * 100 / max_brightness))
      brightness_display="BRT:${brightness}%"
      break
    fi
  done

  battery_percent=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || true)
  battery_status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1 || true)
  if [[ -z "${battery_percent}" ]]; then
    battery_display="BAT:N/A"
  elif [[ "${battery_percent}" -lt 15 && "${battery_status}" != "Charging" ]]; then
    battery_display="BAT:LOW:${battery_percent}%!"
  elif [[ "${battery_status}" == "Charging" ]]; then
    battery_display="BAT:${battery_percent}%+"
  else
    battery_display="BAT:${battery_percent}%"
  fi

  wifi_ssid=$(iwgetid -r 2>/dev/null || true)
  if [[ -n "${wifi_ssid}" ]]; then
    wifi_display="WiFi:${wifi_ssid}"
  else
    wifi_display="WiFi:off"
  fi

  volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1 | sed 's/%//' || true)
  if [[ -n "${volume}" ]]; then
    muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -o 'yes' || true)
    if [[ "${muted}" == "yes" ]]; then
      volume_display="VOL:muted"
    else
      volume_display="VOL:${volume}%"
    fi
  else
    volume_display="VOL:off"
  fi

  datetime=$(date '+%a %d %b %H:%M')

  win_title=$(swaymsg -t get_tree 2>/dev/null \
    | jq -r '.. | objects | select(.focused == true) | .name // empty' 2>/dev/null \
    | head -1 || true)
  win_title=${win_title//$'\n'/ }
  if [[ ${#win_title} -gt 48 ]]; then
    win_title="${win_title:0:45}..."
  fi

  # shellcheck disable=SC2016
  blocks="$(jq -nc \
    --arg title "${win_title}" \
    --arg cpu "CPU:${cpu_usage}%" \
    --arg ram "RAM:${ram_usage}%" \
    --arg disk "DISK:${disk_usage}%" \
    --arg brt "${brightness_display}" \
    --arg bat "${battery_display}" \
    --arg vol "${volume_display}" \
    --arg wifi "${wifi_display}" \
    --arg dt "${datetime}" \
    '
    (if $title == "" then [] else [{name:"title",full_text:($title + "  •"),separator:false,separator_block_width:8}] end)
    + [
      {name:"cpu",full_text:$cpu,separator:true},
      {name:"ram",full_text:$ram,separator:true},
      {name:"disk",full_text:$disk,separator:true},
      {name:"brt",full_text:$brt,separator:true},
      {name:"bat",full_text:$bat,separator:true},
      {name:"vol",full_text:$vol,separator:true},
      {name:"wifi",full_text:$wifi,separator:true,separator_block_width:14},
      {name:"clock",full_text:$dt,separator:false}
    ]
    ')"

  printf ',%s\n' "${blocks}"
  sleep 3
done
