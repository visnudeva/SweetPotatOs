#!/bin/bash
# Potato bar status line. Default is thin (volume · battery · wifi · clock).
# Detailed meters (CPU/RAM/disk/brightness + title) when
# ~/.config/sweetpotatos/status-detail is "on" (Settings → Detailed status bar).
#
# Never call blocking swaymsg/bluetoothctl without timeout: a stuck IPC client
# from status_command can deadlock swirlbar and leave the bar blank until the
# status process is respawned (Settings toggles / Mod+Shift+c).

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

detail_on() {
    local f="${HOME}/.config/sweetpotatos/status-detail"
    [[ -f "$f" ]] && [[ "$(tr -d '[:space:]' <"$f" 2>/dev/null)" == on ]]
}

# Light tray is always on (no icons mode / Settings toggle).
tray_text_on() {
    return 0
}

# Short probe — never block the status loop on compositor IPC / bluetoothd.
# SIGKILL so a wedged swaymsg cannot outlive the timeout and stall the bar.
probe() {
    timeout -s KILL 0.3 "$@" 2>/dev/null
}

build_line() {
    local detail=0
    local cpu_usage=0 ram_usage=0 disk_usage=0
    local brightness_display="" win_title=""
    local battery_display wifi_display volume_display
    local bt_display="" disks_display=""
    local meters line datetime
    local cpu_line total idle total_diff idle_diff
    local user nice system iowait irq softirq steal
    local battery_percent battery_status volume muted
    local wifi_ssid bl max_brightness current_brightness brightness sun
    local bt_name disk_names base d name
    local -a cpu_values

    if detail_on; then
        detail=1
    fi

    if [ "$detail" -eq 1 ]; then
        cpu_line=$(grep 'cpu ' /proc/stat 2>/dev/null) || cpu_line=""
        # shellcheck disable=SC2206
        cpu_values=($cpu_line)
        user=${cpu_values[1]:-0}
        nice=${cpu_values[2]:-0}
        system=${cpu_values[3]:-0}
        idle=${cpu_values[4]:-0}
        iowait=${cpu_values[5]:-0}
        irq=${cpu_values[6]:-0}
        softirq=${cpu_values[7]:-0}
        steal=${cpu_values[8]:-0}

        total=$((user + nice + system + idle + iowait + irq + softirq + steal))

        if [ "$prev_total" -gt 0 ]; then
            total_diff=$((total - prev_total))
            idle_diff=$((idle - prev_idle))
            if [ "$total_diff" -gt 0 ]; then
                cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))
            fi
        fi

        prev_total=$total
        prev_idle=$idle

        ram_usage=$(free -m 2>/dev/null | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')
        ram_usage=${ram_usage:-0}
        disk_usage=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
        disk_usage=${disk_usage:-0}

        brightness_display="$(ico 0xF14E4)"
        for bl in /sys/class/backlight/*; do
            [ -d "$bl" ] || continue
            max_brightness=$(cat "$bl/max_brightness" 2>/dev/null) || continue
            current_brightness=$(cat "$bl/brightness" 2>/dev/null) || continue
            if [ -n "$max_brightness" ] && [ "$max_brightness" -gt 0 ] 2>/dev/null; then
                brightness=$((current_brightness * 100 / max_brightness))
                sun=$((0xF00DA + brightness * 6 / 100))
                if [ "$sun" -gt $((0xF00E0)) ]; then
                    sun=$((0xF00E0))
                fi
                brightness_display="$(ico "$sun") ${brightness}%"
                break
            fi
        done

        # Timed + KILL: swaymsg from status_command can deadlock bar IPC.
        # Single timeout around the pipeline so a stuck swaymsg cannot linger.
        win_title=$(
            timeout -s KILL 0.35 bash -c \
              'swaymsg -t get_tree 2>/dev/null | jq -r ".. | objects | select(.focused == true) | .name // empty" | head -1' \
              2>/dev/null || true
        )
        if [[ "${win_title}" =~ ^([0-9]+):●$ ]]; then
            win_title="${BASH_REMATCH[1]}"
        fi
        win_title=${win_title//$'\n'/ }
        if [ ${#win_title} -gt 28 ]; then
            win_title="${win_title:0:25}..."
        fi
        win_title=$(pango_escape "$win_title")
    fi

    battery_percent=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
    battery_status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
    if [ -z "$battery_percent" ]; then
        battery_display="$(ico 0xF125D)"
    elif [ "$battery_status" = "Charging" ]; then
        battery_display="$(ico 0xF0084) ${battery_percent}%"
    elif [ "$battery_percent" -lt 15 ] 2>/dev/null; then
        battery_display="$(ico 0xF12A1) ${battery_percent}%"
    elif [ "$battery_percent" -lt 50 ] 2>/dev/null; then
        battery_display="$(ico 0xF12A2) ${battery_percent}%"
    else
        battery_display="$(ico 0xF12A3) ${battery_percent}%"
    fi

    wifi_ssid=$(iwgetid -r 2>/dev/null)
    if [ -n "$wifi_ssid" ]; then
        wifi_display="$(ico 0xF05A9) $(pango_escape "$wifi_ssid")"
    else
        wifi_display="$(ico 0xF05AA)"
    fi

    if tray_text_on; then
        if command -v bluetoothctl >/dev/null 2>&1 \
            && probe bluetoothctl show | grep -q 'Powered: yes'; then
            bt_name=$(probe bluetoothctl devices Connected \
                | head -1 | sed 's/^Device [^ ]* //')
            if [ -n "$bt_name" ]; then
                bt_display="$(ico 0xF00AF) $(pango_escape "$bt_name")"
            else
                bt_display="$(ico 0xF00B1)"
            fi
        else
            bt_display="$(ico 0xF00B2)"
        fi
        disk_names=""
        for base in /run/media/"$USER" /media/"$USER"; do
            [ -d "$base" ] || continue
            for d in "$base"/*; do
                [ -d "$d" ] || continue
                name=$(basename "$d")
                if [ -z "$disk_names" ]; then
                    disk_names="$name"
                else
                    disk_names="${disk_names}, ${name}"
                fi
            done
        done
        if [ -n "$disk_names" ]; then
            disks_display="$(ico 0xF0697) $(pango_escape "$disk_names")"
        fi
    fi

    volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1 | sed 's/%//')
    if [ -n "$volume" ]; then
        muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -o 'yes')
        if [ "$muted" = "yes" ]; then
            volume_display="$(ico 0xF075F)"
        elif [ "$volume" -lt 30 ] 2>/dev/null; then
            volume_display="$(ico 0xF057F) ${volume}%"
        elif [ "$volume" -lt 70 ] 2>/dev/null; then
            volume_display="$(ico 0xF0580) ${volume}%"
        else
            volume_display="$(ico 0xF057E) ${volume}%"
        fi
    else
        volume_display="$(ico 0xF0581)"
    fi

    datetime=$(date '+%a %d %b %H:%M')

    if [ "$detail" -eq 1 ]; then
        meters="$(ico 0xF2DB) ${cpu_usage}% · $(ico 0xF035B) ${ram_usage}% · $(ico 0xF02CA) ${disk_usage}% · ${brightness_display} · ${volume_display} · ${battery_display} · ${wifi_display}"
    else
        meters="${volume_display} · ${battery_display} · ${wifi_display}"
    fi
    if [ -n "$bt_display" ]; then
        meters="${meters} · ${bt_display}"
    fi
    if [ -n "$disks_display" ]; then
        meters="${meters} · ${disks_display}"
    fi
    meters="${meters} · ${datetime}"
    if [ "$detail" -eq 1 ] && [ -n "$win_title" ]; then
        line="${win_title}  ·  ${meters}"
    else
        line="${meters}"
    fi
    printf '%s\n' "${line}"
}

while true; do
    # Always print something; a failed probe must not skip a frame.
    build_line || printf '%s\n' "$(date '+%a %d %b %H:%M')"
    sleep 3
done
