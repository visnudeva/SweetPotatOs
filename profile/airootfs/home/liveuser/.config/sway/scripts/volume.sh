#!/usr/bin/env bash
# SweetPotato volume control + mako notification
set -euo pipefail

STEP="${VOLUME_STEP:-5%}"
TAG="sweetpotato-volume"

get_volume() {
  pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%'
}

is_muted() {
  pactl get-sink-mute @DEFAULT_SINK@ | grep -q 'yes'
}

notify_volume() {
  local vol icon text
  if is_muted; then
    vol=0
    icon="notification-audio-volume-muted"
    text="Muted"
  else
    vol="$(get_volume)"
    if (( vol == 0 )); then
      icon="notification-audio-volume-off"
    elif (( vol < 34 )); then
      icon="notification-audio-volume-low"
    elif (( vol < 67 )); then
      icon="notification-audio-volume-medium"
    else
      icon="notification-audio-volume-high"
    fi
    text="Volume ${vol}%"
  fi

  notify-send -t 1500 -a "Volume" -i "${icon}" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    -h "int:value:${vol}" \
    "Audio" "${text}"
}

notify_mic() {
  local muted text icon
  muted="$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')"
  if [[ "${muted}" == "yes" ]]; then
    icon="microphone-sensitivity-muted"
    text="Microphone muted"
  else
    icon="microphone-sensitivity-high"
    text="Microphone on"
  fi
  notify-send -t 1500 -a "Microphone" -i "${icon}" \
    -h "string:x-canonical-private-synchronous:sweetpotato-mic" \
    -h "string:x-dunst-stack-tag:sweetpotato-mic" \
    "Audio" "${text}"
}

case "${1:-}" in
  up)
    pactl set-sink-mute @DEFAULT_SINK@ 0
    pactl set-sink-volume @DEFAULT_SINK@ "+${STEP}"
    notify_volume
    ;;
  down)
    pactl set-sink-volume @DEFAULT_SINK@ "-${STEP}"
    notify_volume
    ;;
  mute)
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    notify_volume
    ;;
  mic)
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
    notify_mic
    ;;
  *)
    echo "Usage: $0 {up|down|mute|mic}" >&2
    exit 1
    ;;
esac
