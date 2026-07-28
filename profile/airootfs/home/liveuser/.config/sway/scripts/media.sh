#!/usr/bin/env bash
# SweetPotato media keys + mako notification
set -euo pipefail

TAG="sweetpotato-media"

notify_media() {
  local status artist title icon text
  status="$(playerctl status 2>/dev/null || echo "Stopped")"
  artist="$(playerctl metadata artist 2>/dev/null || true)"
  title="$(playerctl metadata title 2>/dev/null || true)"

  case "${status}" in
    Playing) icon="media-playback-start" ;;
    Paused)  icon="media-playback-pause" ;;
    *)       icon="media-playback-stop" ;;
  esac

  if [[ -n "${title}" ]]; then
    text="${title}"
    [[ -n "${artist}" ]] && text="${artist} — ${title}"
  else
    text="${status}"
  fi

  notify-send -t 2000 -a "Media" -i "${icon}" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "Media · ${status}" "${text}"
}

case "${1:-}" in
  play-pause)
    playerctl play-pause
    sleep 0.05
    notify_media
    ;;
  next)
    playerctl next
    sleep 0.05
    notify_media
    ;;
  prev)
    playerctl previous
    sleep 0.05
    notify_media
    ;;
  stop)
    playerctl stop
    notify-send -t 1500 -a "Media" -i "media-playback-stop" \
      -h "string:x-canonical-private-synchronous:${TAG}" \
      "Media" "Stopped"
    ;;
  *)
    echo "Usage: $0 {play-pause|next|prev|stop}" >&2
    exit 1
    ;;
esac
