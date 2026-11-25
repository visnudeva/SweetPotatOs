#!/usr/bin/env bash
# Status bar density: thin (default) or detailed meters.
# State: ~/.config/sweetpotatos/status-detail — "on" or "off" (missing = off).
# Usage: status-detail.sh [on|off|toggle|status]
set -euo pipefail

ROOT="${SPO_CONFIG_ROOT:-${HOME}/.config}"
STATE_DIR="${ROOT}/sweetpotatos"
STATE_FILE="${STATE_DIR}/status-detail"
TAG="sweetpotato-status-detail"

notify() {
  local title="$1" body="$2"
  notify-send -t 2500 -a "Status bar" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "${body}" || true
}

state_now() {
  if [[ -f "${STATE_FILE}" ]] && [[ "$(tr -d '[:space:]' <"${STATE_FILE}")" == on ]]; then
    echo on
  else
    echo off
  fi
}

write_state() {
  mkdir -p "${STATE_DIR}"
  printf '%s\n' "$1" >"${STATE_FILE}"
}

# swirlbar only kills/respawns status_command when the command *string* changes.
# Re-setting the same path is a no-op and leaves a stuck status line blank —
# clear first (`-`), then set again.
restart_bar_status() {
  local script="${ROOT}/swirl/scripts/status.sh"
  [[ -f "${script}" ]] || script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/status.sh"
  command -v swaymsg >/dev/null 2>&1 || return 0
  swaymsg -q 'bar potato status_command -' >/dev/null 2>&1 || true
  sleep 0.05
  swaymsg -q "bar potato status_command ${script}" >/dev/null 2>&1 || true
}

cmd="${1:-toggle}"
case "${cmd}" in
  status)
    state_now
    ;;
  on|enable)
    write_state on
    restart_bar_status
    notify "Detailed status" "CPU, RAM, disk, brightness, and window title in the bar"
    ;;
  off|disable)
    write_state off
    restart_bar_status
    notify "Thin status" "Volume, battery, network, and clock"
    ;;
  toggle)
    if [[ "$(state_now)" == on ]]; then
      write_state off
      restart_bar_status
      notify "Thin status" "Volume, battery, network, and clock"
    else
      write_state on
      restart_bar_status
      notify "Detailed status" "CPU, RAM, disk, brightness, and window title in the bar"
    fi
    ;;
  *)
    echo "Usage: $0 [on|off|toggle|status]" >&2
    exit 2
    ;;
esac
