#!/bin/bash

# Store previous CPU values for calculating usage
prev_total=0
prev_idle=0

# Monochrome glyphs from Symbols Nerd Font Mono (ttf-nerd-fonts-symbols-mono).
# The bar font stays Noto Sans; only these spans switch face.
ico() {
    printf '<span font="Symbols Nerd Font Mono 10">&#x%X;</span>' "$1"
}

pango_escape() {
    local s=$1
    # In ${var/pattern/repl}, & means the matched text, so a literal & is \&.
    s=${s//&/\&amp;}
    s=${s//</\&lt;}
    s=${s//>/\&gt;}
    printf '%s' "$s"
}

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

    # Brightness. No backlight (a desktop) is a crossed-out sun.
    # Otherwise the sun grows from dim to full with the percentage.
    brightness_display="$(ico 0xF14E4)"
    for bl in /sys/class/backlight/*; do
        [ -d "$bl" ] || continue
        max_brightness=$(cat "$bl/max_brightness" 2>/dev/null) || continue
        current_brightness=$(cat "$bl/brightness" 2>/dev/null) || continue
        if [ -n "$max_brightness" ] && [ "$max_brightness" -gt 0 ]; then
            brightness=$((current_brightness * 100 / max_brightness))
            sun=$((0xF00DA + brightness * 6 / 100))
            if [ "$sun" -gt $((0xF00E0)) ]; then
                sun=$((0xF00E0))
            fi
            brightness_display="$(ico "$sun") ${brightness}%"
            break
        fi
    done

    # Battery. The glyph changes for charging, low, and no battery.
    battery_percent=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
    battery_status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
    if [ -z "$battery_percent" ]; then
        battery_display="$(ico 0xF125D)"
    elif [ "$battery_status" = "Charging" ]; then
        battery_display="$(ico 0xF0084) ${battery_percent}%"
    elif [ "$battery_percent" -lt 15 ]; then
        battery_display="$(ico 0xF12A1) ${battery_percent}%"
    elif [ "$battery_percent" -lt 50 ]; then
        battery_display="$(ico 0xF12A2) ${battery_percent}%"
    else
        battery_display="$(ico 0xF12A3) ${battery_percent}%"
    fi

    # WiFi. The name stays text; off is a slashed icon.
    wifi_ssid=$(iwgetid -r 2>/dev/null)
    if [ -n "$wifi_ssid" ]; then
        wifi_display="$(ico 0xF05A9) $(pango_escape "$wifi_ssid")"
    else
        wifi_display="$(ico 0xF05AA)"
    fi

    # Volume. Muted and missing audio use their own icons.
    volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1 | sed 's/%//')
    if [ -n "$volume" ]; then
        muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -o 'yes')
        if [ "$muted" = "yes" ]; then
            volume_display="$(ico 0xF075F)"
        elif [ "$volume" -lt 30 ]; then
            volume_display="$(ico 0xF057F) ${volume}%"
        elif [ "$volume" -lt 70 ]; then
            volume_display="$(ico 0xF0580) ${volume}%"
        else
            volume_display="$(ico 0xF057E) ${volume}%"
        fi
    else
        volume_display="$(ico 0xF0581)"
    fi

    # Date/Time
    datetime=$(date '+%a %d %b %H:%M')

    # Focused window title (truncate so metrics stay readable).
    # An empty workspace is focused as "N:●"; the buttons on the left stay
    # discs, and this label is just the number.
    win_title=$(swaymsg -t get_tree 2>/dev/null \
      | jq -r '.. | objects | select(.focused == true) | .name // empty' 2>/dev/null \
      | head -1)
    if [[ "${win_title}" =~ ^([0-9]+):●$ ]]; then
        win_title="${BASH_REMATCH[1]}"
    fi
    win_title=${win_title//$'\n'/ }
    if [ ${#win_title} -gt 48 ]; then
        win_title="${win_title:0:45}..."
    fi
    win_title=$(pango_escape "$win_title")

    meters="$(ico 0xF2DB) ${cpu_usage}% • $(ico 0xF035B) ${ram_usage}% • $(ico 0xF02CA) ${disk_usage}% • ${brightness_display} • ${volume_display} • ${battery_display} • ${wifi_display} • ${datetime}"
    if [ -n "$win_title" ]; then
        line="${win_title}  •  ${meters}"
    else
        line="${meters}"
    fi
    # Extra space under the glyphs. swaybar centers the line, which lifts
    # descenders (the p in a window title, the p in Sep) off the bottom
    # edge that shows under the app menu.
    echo "<span rise=\"8192\">${line}</span>"

    sleep 3
done
