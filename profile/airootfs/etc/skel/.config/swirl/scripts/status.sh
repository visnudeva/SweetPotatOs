#!/bin/bash
# Potato bar status line — thin only:
# volume · battery · wifi · bluetooth · mounts · clock
#
# Never call blocking bluetoothctl without timeout: a stuck probe from
# status_command can leave the bar blank until the status process is respawned.

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

# Short probe — never block the status loop on bluetoothd.
# SIGKILL so a wedged client cannot outlive the timeout and stall the bar.
probe() {
    timeout -s KILL 0.3 "$@" 2>/dev/null
}

build_line() {
    local battery_display wifi_display volume_display
    local bt_display="" disks_display=""
    local meters datetime
    local battery_percent battery_status volume muted
    local wifi_ssid bt_name disk_names base d name

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

    meters="${volume_display} · ${battery_display} · ${wifi_display} · ${bt_display}"
    if [ -n "$disks_display" ]; then
        meters="${meters} · ${disks_display}"
    fi
    meters="${meters} · ${datetime}"
    printf '%s\n' "${meters}"
}

while true; do
    # Always print something; a failed probe must not skip a frame.
    build_line || printf '%s\n' "$(date '+%a %d %b %H:%M')"
    sleep 10
done
