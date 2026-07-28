#!/usr/bin/env bash
# SweetPotato brightness control + mako notification
set -euo pipefail

STEP="${BRIGHTNESS_STEP:-5%}"
TAG="sweetpotato-brightness"

get_brightness() {
  brightnessctl -m | awk -F, '{gsub(/%/,"",$4); print $4}'
}

notify_brightness() {
  local level icon
  level="$(get_brightness)"
  if (( level < 20 )); then
    icon="notification-display-brightness-off"
  elif (( level < 40 )); then
    icon="notification-display-brightness-low"
  elif (( level < 70 )); then
    icon="notification-display-brightness-medium"
  elif (( level < 90 )); then
    icon="notification-display-brightness-high"
  else
    icon="notification-display-brightness-full"
  fi

  notify-send -t 1500 -a "Brightness" -i "${icon}" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    -h "int:value:${level}" \
    "Brightness" "${level}%"
}

case "${1:-}" in
  up)
    brightnessctl set "+${STEP}" >/dev/null
    notify_brightness
    ;;
  down)
    brightnessctl set "${STEP}-" >/dev/null
    notify_brightness
    ;;
  *)
    echo "Usage: $0 {up|down}" >&2
    exit 1
    ;;
esac
