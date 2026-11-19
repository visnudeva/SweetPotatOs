#!/usr/bin/env bash
# Overview packing: stripe (coverflow bands) or wall (equal-size grid).
# State: ~/.config/sweetpotatos/overview-layout ("stripe" or "wall"). Missing = stripe.
# Usage: overview-layout.sh [stripe|wall|toggle|status|apply]
set -euo pipefail

ROOT="${SPO_CONFIG_ROOT:-${HOME}/.config}"
STATE_DIR="${ROOT}/sweetpotatos"
STATE_FILE="${STATE_DIR}/overview-layout"
TAG="sweetpotato-overview-layout"

notify() {
  local title="$1" body="$2"
  notify-send -t 2500 -a "Overview" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "${body}" || true
}

state_now() {
  if [[ -f "${STATE_FILE}" ]] && [[ "$(<"${STATE_FILE}")" == "wall" ]]; then
    echo wall
  else
    echo stripe
  fi
}

write_state() {
  mkdir -p "${STATE_DIR}"
  printf '%s\n' "$1" >"${STATE_FILE}"
}

apply_now() {
  swaymsg "overview_layout $(state_now)" >/dev/null || true
}

cmd="${1:-toggle}"
case "${cmd}" in
  status)
    state_now
    ;;
  stripe)
    write_state stripe
    apply_now
    notify "overview stripes" "Desktops stacked as equal bands"
    ;;
  wall)
    write_state wall
    apply_now
    notify "overview wall" "Desktops as equal tiles"
    ;;
  apply)
    apply_now
    ;;
  toggle)
    if [[ "$(state_now)" == "wall" ]]; then
      write_state stripe
      apply_now
      notify "overview stripes" "Desktops stacked as equal bands"
    else
      write_state wall
      apply_now
      notify "overview wall" "Desktops as equal tiles"
    fi
    ;;
  *)
    echo "Usage: $0 [stripe|wall|toggle|status|apply]" >&2
    exit 2
    ;;
esac
