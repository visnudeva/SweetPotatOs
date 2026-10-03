#!/usr/bin/env bash
# Toggle Swirl's rounded window corners and the autotile inner gap together.
# State: ~/.config/sweetpotatos/frame ("on" or "off"). Missing means on.
# Usage: frame.sh [on|off|toggle|apply]
set -euo pipefail

ROOT="${SPO_CONFIG_ROOT:-${HOME}/.config}"
STATE_DIR="${ROOT}/sweetpotatos"
STATE_FILE="${STATE_DIR}/frame"
RADIUS_ON=8
TAG="sweetpotato-frame"

notify() {
  local title="$1" body="$2"
  notify-send -t 2500 -a "Frame" \
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

view_ids() {
  swaymsg -t get_tree | python3 -c '
import json, sys
def walk(n):
    if isinstance(n, dict):
        if n.get("pid") and n.get("id") is not None:
            print(n["id"])
        for key in ("nodes", "floating_nodes"):
            for child in n.get(key) or []:
                walk(child)
    elif isinstance(n, list):
        for child in n:
            walk(child)
walk(json.load(sys.stdin))
'
}

apply_now() {
  local st radius=0
  st="$(state_now)"
  if [[ "${st}" == "on" ]]; then
    radius="${RADIUS_ON}"
  fi
  swaymsg "default_decoration border_radius ${radius}" >/dev/null
  local ids cmd="" id
  ids="$(view_ids 2>/dev/null || true)"
  if [[ -n "${ids}" ]]; then
    while IFS= read -r id; do
      [[ -n "${id}" ]] || continue
      cmd+="[con_id=${id}] decoration border_radius ${radius}; "
    done <<<"${ids}"
    swaymsg "${cmd}" >/dev/null || true
  fi
  if [[ "${st}" == "off" ]]; then
    # Autotile only retouches the focused workspace. Clear the rest here.
    swaymsg "gaps inner all set 0" >/dev/null || true
  fi
  # Ask autotile to re-read the state file and set the focused workspace.
  swaymsg "mark --add __spo_gaps" >/dev/null 2>&1 || true
  swaymsg "unmark __spo_gaps" >/dev/null 2>&1 || true
}

cmd="${1:-toggle}"
case "${cmd}" in
  on|enable)
    write_state on
    apply_now
    notify "Corners and gaps on" "Rounded frames, and a gap when several windows are tiled"
    ;;
  off|disable)
    write_state off
    apply_now
    notify "Corners and gaps off" "Square frames, windows sit edge to edge"
    ;;
  toggle)
    if [[ "$(state_now)" == "off" ]]; then
      write_state on
      apply_now
      notify "Corners and gaps on" "Rounded frames, and a gap when several windows are tiled"
    else
      write_state off
      apply_now
      notify "Corners and gaps off" "Square frames, windows sit edge to edge"
    fi
    ;;
  apply)
    # Reload parses default_decoration 8 before IPC accepts commands.
    if [[ "$(state_now)" == "on" ]]; then
      exit 0
    fi
    (sleep 0.4; "$0" apply-now) &
    disown || true
    ;;
  apply-now)
    apply_now
    ;;
  *)
    echo "Usage: $(basename "$0") [on|off|toggle|apply]" >&2
    exit 2
    ;;
esac
