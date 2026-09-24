#!/bin/bash

# Store previous CPU values for calculating usage
prev_total=0
prev_idle=0

while true; do
    # CPU usage (current percentage)
    cpu_line=$(grep 'cpu ' /proc/stat)
    cpu_values=($cpu_line)
    user=${cpu_values[1]}
    nice=${cpu_values[2]}
    system=${cpu_values[3]}
    idle=${cpu_values[4]}
    iowait=${cpu_values[5]}
    irq=${cpu_values[6]}
    softirq=${cpu_values[7]}
    steal=${cpu_values[8]}

    total=$((user + nice + system + idle + iowait + irq + softirq + steal))

    if [ $prev_total -gt 0 ]; then
        total_diff=$((total - prev_total))
        idle_diff=$((idle - prev_idle))
        if [ "$total_diff" -gt 0 ]; then
            cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))
        else
            cpu_usage=0
        fi
    else
        cpu_usage=0
    fi

    prev_total=$total
    prev_idle=$idle

    # RAM (current percentage)
    ram_usage=$(free -m | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')

    # Disk
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    # Brightness
    brightness_display="BRT:off"
    for bl in /sys/class/backlight/*; do
        [ -d "$bl" ] || continue
        max_brightness=$(cat "$bl/max_brightness" 2>/dev/null) || continue
        current_brightness=$(cat "$bl/brightness" 2>/dev/null) || continue
        if [ -n "$max_brightness" ] && [ "$max_brightness" -gt 0 ]; then
            brightness=$((current_brightness * 100 / max_brightness))
            brightness_display="BRT:${brightness}%"
            break
        fi
    done

    # Battery with status
    battery_percent=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
    battery_status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
    if [ -z "$battery_percent" ]; then
        battery_display="N/A"
    elif [ "$battery_percent" -lt 15 ] && [ "$battery_status" != "Charging" ]; then
        battery_display="LOW:${battery_percent}%!"
    elif [ "$battery_status" = "Charging" ]; then
        battery_display="${battery_percent}%+"
    else
        battery_display="${battery_percent}%"
    fi

    # WiFi (show SSID if connected)
    wifi_ssid=$(iwgetid -r 2>/dev/null)
    if [ -n "$wifi_ssid" ]; then
        wifi_display="WiFi:${wifi_ssid}"
    else
        wifi_display="WiFi:off"
    fi

    # Volume
    volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1 | sed 's/%//')
    if [ -n "$volume" ]; then
        muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -o 'yes')
        if [ "$muted" = "yes" ]; then
            volume_display="VOL:muted"
        else
            volume_display="VOL:${volume}%"
        fi
    else
        volume_display="VOL:off"
    fi

    # Date/Time
    datetime=$(date '+%a %d %b %H:%M')

    # Focused window title (truncate so metrics stay readable)
    win_title=$(swaymsg -t get_tree 2>/dev/null \
      | jq -r '.. | objects | select(.focused == true) | .name // empty' 2>/dev/null \
      | head -1)
    win_title=${win_title//$'\n'/ }
    if [ ${#win_title} -gt 48 ]; then
        win_title="${win_title:0:45}..."
    fi

    if [ -n "$win_title" ]; then
        echo "${win_title}  •  CPU:${cpu_usage}% • RAM:${ram_usage}% • DISK:${disk_usage}% • ${brightness_display} • BAT:${battery_display} • ${volume_display} • ${wifi_display} • ${datetime}"
    else
        echo "CPU:${cpu_usage}% • RAM:${ram_usage}% • DISK:${disk_usage}% • ${brightness_display} • BAT:${battery_display} • ${volume_display} • ${wifi_display} • ${datetime}"
    fi

    sleep 3
done
