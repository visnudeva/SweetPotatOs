#!/usr/bin/env bash
# SweetPotato caffeine — prevent idle lock / display off / sleep
# Usage: caffeine.sh [on|off|toggle]  (default: toggle)
set -euo pipefail

TAG="sweetpotato-caffeine"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-caffeine.pid"
STATEFILE="${XDG_RUNTIME_DIR:-/tmp}/sweetpotato-caffeine.state"

notify() {
  local icon="$1" title="$2" body="$3"
  notify-send -t 2500 -a "Caffeine" -i "${icon}" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "${body}"
}

is_active() {
  [[ -f "${STATEFILE}" ]] && [[ "$(<"${STATEFILE}")" == "on" ]]
}

inhibit_alive() {
  [[ -f "${PIDFILE}" ]] || return 1
  kill -0 "$(<"${PIDFILE}")" 2>/dev/null
}

start_swayidle() {
  pkill -x swayidle 2>/dev/null || true
  # Match timeouts from sway/config
  swayidle -w \
    timeout 300 'swaylock -f' \
    timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    before-sleep 'swaylock -f' &
  disown || true
}

enable_caffeine() {
  # Idempotent: already on with a live inhibit — nothing to do
  if is_active && inhibit_alive; then
    return 0
  fi
  pkill -x swayidle 2>/dev/null || true
  if [[ -f "${PIDFILE}" ]]; then
    kill "$(<"${PIDFILE}")" 2>/dev/null || true
    rm -f "${PIDFILE}"
  fi
  systemd-inhibit --what=idle:sleep --who=SweetPotato --why="Caffeine mode" --mode=block \
    sleep infinity &
  echo $! > "${PIDFILE}"
  echo "on" > "${STATEFILE}"
  notify "preferences-desktop-screensaver" "Caffeine on" "Sleep and lock disabled"
}

disable_caffeine() {
  if [[ -f "${PIDFILE}" ]]; then
    kill "$(<"${PIDFILE}")" 2>/dev/null || true
    rm -f "${PIDFILE}"
  fi
  echo "off" > "${STATEFILE}"
  start_swayidle
  notify "system-lock-screen" "Caffeine off" "Sleep and lock restored"
}

cmd="${1:-toggle}"
case "${cmd}" in
  on|enable)
    enable_caffeine
    ;;
  off|disable)
    disable_caffeine
    ;;
  toggle)
    if is_active && inhibit_alive; then
      disable_caffeine
    else
      enable_caffeine
    fi
    ;;
  *)
    echo "Usage: $(basename "$0") [on|off|toggle]" >&2
    exit 1
    ;;
esac
