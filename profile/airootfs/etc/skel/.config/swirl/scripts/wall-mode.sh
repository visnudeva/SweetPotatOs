#!/usr/bin/env bash
# Toggle newm-style wall mode (2D tile grid + zoom). See WALL.md in swirl.
# State: ~/.config/sweetpotatos/wall-mode ("on" or "off"). Missing means off.
# Usage: wall-mode.sh [on|off|toggle|status|apply]
set -euo pipefail

ROOT="${SPO_CONFIG_ROOT:-${HOME}/.config}"
STATE_DIR="${ROOT}/sweetpotatos"
STATE_FILE="${STATE_DIR}/wall-mode"
TAG="sweetpotato-wall-mode"

notify() {
  local title="$1" body="$2"
  notify-send -t 2500 -a "Wall mode" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "${body}" || true
}

state_now() {
  if [[ -f "${STATE_FILE}" ]] && [[ "$(<"${STATE_FILE}")" == "on" ]]; then
    echo on
  else
    echo off
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
    swaymsg "wall_mode enable" >/dev/null || true
  else
    swaymsg "wall_mode disable" >/dev/null || true
  fi
  # Wall/overview touch layer-shell; re-assert swirlbar chrome if frames are on.
  if [[ -x "${ROOT}/swirl/scripts/frame.sh" ]]; then
    "${ROOT}/swirl/scripts/frame.sh" apply >/dev/null 2>&1 || true
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
    notify "wall mode on" "Pan: Mod+Alt+arrows · Zoom: Mod+Alt+u/n"
    ;;
  off)
    write_state off
    apply_now
    notify "wall mode off" "Strip scrolls on its primary axis again"
    ;;
  apply)
    apply_now
    ;;
  toggle)
    if [[ "$(state_now)" == "on" ]]; then
      write_state off
      apply_now
      notify "wall mode off" "Strip scrolls on its primary axis again"
    else
      write_state on
      apply_now
      notify "wall mode on" "Pan: Mod+Alt+arrows · Zoom: Mod+Alt+u/n"
    fi
    ;;
  *)
    echo "Usage: $0 [on|off|toggle|status|apply]" >&2
    exit 2
    ;;
esac
