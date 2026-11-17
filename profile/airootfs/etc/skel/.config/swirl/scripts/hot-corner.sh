#!/usr/bin/env bash
# Toggle the top-left overview hot corner.
# State: ~/.config/sweetpotatos/hot-corner ("on" or "off"). Missing means on.
# Usage: hot-corner.sh [on|off|toggle|status|apply]
set -euo pipefail

ROOT="${SPO_CONFIG_ROOT:-${HOME}/.config}"
STATE_DIR="${ROOT}/sweetpotatos"
STATE_FILE="${STATE_DIR}/hot-corner"
TAG="sweetpotato-hot-corner"

notify() {
  local title="$1" body="$2"
  notify-send -t 2500 -a "Hot corner" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "${body}" || true
}

state_now() {
  if [[ -f "${STATE_FILE}" ]] && [[ "$(<"${STATE_FILE}")" == "off" ]]; then
    echo off
  else
    echo on
  fi
}

write_state() {
  mkdir -p "${STATE_DIR}"
  printf '%s\n' "$1" >"${STATE_FILE}"
}

apply_now() {
  local st
  st="$(state_now)"
  if [[ "${st}" == "on" ]]; then
    swaymsg "overview_hot_corner yes" >/dev/null || true
  else
    swaymsg "overview_hot_corner no" >/dev/null || true
  fi
}

cmd="${1:-toggle}"
case "${cmd}" in
  status)
    state_now
    ;;
  on)
    write_state on
    apply_now
    notify "hot corner on" "Top-left opens overview"
    ;;
  off)
    write_state off
    apply_now
    notify "hot corner off" "Top-left does nothing"
    ;;
  apply)
    apply_now
    ;;
  toggle)
    if [[ "$(state_now)" == "on" ]]; then
      write_state off
      apply_now
      notify "hot corner off" "Top-left does nothing"
    else
      write_state on
      apply_now
      notify "hot corner on" "Top-left opens overview"
    fi
    ;;
  *)
    echo "Usage: $0 [on|off|toggle|status|apply]" >&2
    exit 2
    ;;
esac
