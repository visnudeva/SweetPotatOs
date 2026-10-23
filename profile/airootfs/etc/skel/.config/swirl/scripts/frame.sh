#!/usr/bin/env bash
# Toggle Swirl's rounded window corners, window gaps, and swirlbar chrome.
# State: ~/.config/sweetpotatos/frame ("on" or "off"). Missing means on.
# This script owns bar chrome and hide_edge_borders — autotile only mirrors
# per-workspace inner gaps and must not fight these IPC calls.
# Usage: frame.sh [on|off|toggle|apply]
set -euo pipefail

ROOT="${SPO_CONFIG_ROOT:-${HOME}/.config}"
STATE_DIR="${ROOT}/sweetpotatos"
STATE_FILE="${STATE_DIR}/frame"
RADIUS_ON=8
BAR_BORDER=2
BAR_ID=potato
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
  local st radius=0 gap=0 bar_border=0 edge_borders=smart
  st="$(state_now)"
  if [[ "${st}" == "on" ]]; then
    radius="${RADIUS_ON}"
    gap="${RADIUS_ON}"
    bar_border="${BAR_BORDER}"
    # smart_no_gaps only looks at outer gaps; inner gaps alone still hide a
    # lone window's border. none keeps the focused stroke in gap mode.
    edge_borders=none
  fi

  swaymsg "default_decoration border_radius ${radius}" >/dev/null || true
  # `hide_edge_borders none` alone used to leave a sticky smart flag from a
  # previous flush mode; clear it explicitly when gaps are on.
  if [[ "${edge_borders}" == none ]]; then
    swaymsg "hide_edge_borders none; smart_borders off" >/dev/null || true
  else
    swaymsg "hide_edge_borders smart" >/dev/null || true
  fi

  local ids cmd="" id
  ids="$(view_ids 2>/dev/null || true)"
  if [[ -n "${ids}" ]]; then
    while IFS= read -r id; do
      [[ -n "${id}" ]] || continue
      cmd+="[con_id=${id}] decoration border_radius ${radius}; "
    done <<<"${ids}"
    swaymsg "${cmd}" >/dev/null || true
  fi

  swaymsg "gaps inner all set ${gap}" >/dev/null || true
  if (( radius > 0 )); then
    swaymsg "bar ${BAR_ID} gaps ${gap} ${gap} 0 ${gap}; bar ${BAR_ID} border_radius ${radius}; bar ${BAR_ID} border ${bar_border}" >/dev/null || true
  else
    swaymsg "bar ${BAR_ID} gaps 0; bar ${BAR_ID} border 0; bar ${BAR_ID} border_radius 0" >/dev/null || true
  fi

  # Keep autotile's gap cache in sync with the state file.
  swaymsg "mark --add __spo_gaps" >/dev/null 2>&1 || true
  swaymsg "unmark __spo_gaps" >/dev/null 2>&1 || true
}

cmd="${1:-toggle}"
case "${cmd}" in
  on|enable)
    write_state on
    apply_now
    notify "Corners and gaps on" "Rounded frames, floating bar, and a gap around tiled windows"
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
      notify "Corners and gaps on" "Rounded frames, floating bar, and a gap around tiled windows"
    else
      write_state off
      apply_now
      notify "Corners and gaps off" "Square frames, windows sit edge to edge"
    fi
    ;;
  apply)
    # Always re-apply after reload/login. Theme apply can reload Swirl a
    # second or two later and reset the bar block to flush defaults — the
    # early-exit-when-on path left chrome stuck off. Wait until IPC accepts
    # runtime bar/gaps commands.
    (sleep 0.6; "$0" apply-now) &
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
