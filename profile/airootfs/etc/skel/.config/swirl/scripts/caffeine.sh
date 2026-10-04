#!/usr/bin/env bash
# SweetPotato caffeine — stop idle lock and display-off.
# Idle is the swayidle timeouts only. Do not take a systemd-inhibit lock:
# a lock held across lid sleep leaves some machines unable to wake.
# Usage: caffeine.sh [on|off|toggle]  (default: toggle)
set -euo pipefail

TAG="sweetpotato-caffeine"
RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PIDFILE="${RUNTIME}/sweetpotato-caffeine.pid"
STATEFILE="${RUNTIME}/sweetpotato-caffeine.state"
LOCKCFG="${HOME}/.config/swaylock/config"

notify() {
  local icon="$1" title="$2"
  notify-send -t 2500 -a "Caffeine" -i "${icon}" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "" 2>/dev/null || true
}

is_active() {
  [[ -f "${STATEFILE}" ]] && [[ "$(<"${STATEFILE}")" == "on" ]]
}

# Kill a process and anything it started.
kill_tree() {
  local pid="$1" child
  [[ -n "${pid}" && "${pid}" != 0 ]] || return 0
  for child in $(pgrep -P "${pid}" 2>/dev/null || true); do
    kill_tree "${child}"
  done
  kill "${pid}" 2>/dev/null || true
}

# Older caffeine held an idle inhibitor. Drop that, and its supervisor.
drop_held_lock() {
  local pid
  if [[ -f "${PIDFILE}" ]]; then
    kill_tree "$(<"${PIDFILE}")"
    rm -f "${PIDFILE}"
  fi
  while read -r pid; do
    [[ -z "${pid}" || "${pid}" == "$$" || "${pid}" == "${BASHPID}" ]] && continue
    kill "${pid}" 2>/dev/null || true
  done < <(pgrep -f 'systemd-inhibit --what=idle --who=SweetPotato' || true)
}

start_swayidle() {
  pkill -x swayidle 2>/dev/null || true
  # Match timeouts from swirl/config
  swayidle -w \
    timeout 300 "swaylock -f -C ${LOCKCFG}" \
    timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    before-sleep "swaylock -f -C ${LOCKCFG}" \
    after-resume 'swaymsg "output * enable"; swaymsg "output * power on"' &
  disown || true
}

# No idle timeouts. Lid suspend still locks, and the display comes back after wake.
start_sleep_watch() {
  pkill -x swayidle 2>/dev/null || true
  swayidle -w \
    before-sleep "swaylock -f -C ${LOCKCFG}" \
    after-resume 'swaymsg "output * enable"; swaymsg "output * power on"' &
  disown || true
}

enable_caffeine() {
  local was_on=0
  if is_active; then
    was_on=1
  fi
  drop_held_lock
  start_sleep_watch
  echo "on" > "${STATEFILE}"
  if [[ "${was_on}" -eq 0 ]]; then
    notify "preferences-desktop-screensaver" "caffeine on"
  fi
}

disable_caffeine() {
  drop_held_lock
  echo "off" > "${STATEFILE}"
  start_swayidle
  notify "system-lock-screen" "caffeine off"
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
    if is_active; then
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
