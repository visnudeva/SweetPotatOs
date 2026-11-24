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

cmd="${1:-toggle}"
case "${cmd}" in
  status)
    state_now
    ;;
  on|enable)
    write_state on
    notify "Detailed status" "CPU, RAM, disk, brightness, and window title in the bar"
    ;;
  off|disable)
    write_state off
    notify "Thin status" "Volume, battery, network, and clock"
    ;;
  toggle)
    if [[ "$(state_now)" == on ]]; then
      write_state off
      notify "Thin status" "Volume, battery, network, and clock"
    else
      write_state on
      notify "Detailed status" "CPU, RAM, disk, brightness, and window title in the bar"
    fi
    ;;
  *)
    echo "Usage: $0 [on|off|toggle|status]" >&2
    exit 2
    ;;
esac
