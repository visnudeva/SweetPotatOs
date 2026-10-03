#!/usr/bin/env bash
# SweetPotato caffeine — stop idle lock and display-off.
# The lock is idle only, so closing the lid still suspends.
# Power-off and lid sleep drop the lock first. Leaving it held makes
# some machines stop with the power light on and then never wake.
# Usage: caffeine.sh [on|off|toggle]  (default: toggle)
set -euo pipefail

TAG="sweetpotato-caffeine"
RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PIDFILE="${RUNTIME}/sweetpotato-caffeine.pid"
STATEFILE="${RUNTIME}/sweetpotato-caffeine.state"
LOCKCFG="${HOME}/.config/swaylock/config"

notify() {
  local icon="$1" title="$2" body="$3"
  notify-send -t 2500 -a "Caffeine" -i "${icon}" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "${body}" 2>/dev/null || true
}

is_active() {
  [[ -f "${STATEFILE}" ]] && [[ "$(<"${STATEFILE}")" == "on" ]]
}

inhibit_alive() {
  [[ -f "${PIDFILE}" ]] || return 1
  kill -0 "$(<"${PIDFILE}")" 2>/dev/null
}

logind_flag() {
  local prop="$1"
  busctl --system get-property org.freedesktop.login1 /org/freedesktop/login1 \
    org.freedesktop.login1.Manager "${prop}" 2>/dev/null || true
}

# Kill a process and anything it started. A plain kill leaves the idle
# lock held if the inhibitor's children keep the fd open.
kill_tree() {
  local pid="$1" child
  [[ -n "${pid}" && "${pid}" != 0 ]] || return 0
  for child in $(pgrep -P "${pid}" 2>/dev/null || true); do
    kill_tree "${child}"
  done
  kill "${pid}" 2>/dev/null || true
}

start_swayidle() {
  pkill -x swayidle 2>/dev/null || true
  # Match timeouts from swirl/config
  swayidle -w \
    timeout 300 "swaylock -f -C ${LOCKCFG}" \
    timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    before-sleep "swaylock -f -C ${LOCKCFG}" &
  disown || true
}

# No idle timeouts. Lid suspend still locks, and the display comes back after wake.
start_sleep_watch() {
  pkill -x swayidle 2>/dev/null || true
  swayidle -w \
    before-sleep "swaylock -f -C ${LOCKCFG}" \
    after-resume 'swaymsg "output * power on"' &
  disown || true
}

# Holds an idle lock, and drops it for shutdown or lid sleep.
# Sleep stays down until logind says the machine is awake again.
supervise() {
  local inh=0
  release_inhibit() {
    if [[ "${inh}" -ne 0 ]]; then
      kill_tree "${inh}"
      wait "${inh}" 2>/dev/null || true
      inh=0
    fi
  }
  take_inhibit() {
    release_inhibit
    # idle only — do not take sleep, shutdown, or lid locks
    systemd-inhibit --what=idle --who=SweetPotato --why="Caffeine mode" --mode=block \
      sleep infinity &
    inh=$!
  }
  cleanup() {
    trap - TERM INT HUP
    release_inhibit
    # $BASHPID changes inside $(...), so save it before looking up children.
    local me="${BASHPID}" child
    for child in $(pgrep -P "${me}" 2>/dev/null || true); do
      kill_tree "${child}"
    done
    exit 0
  }
  trap cleanup TERM INT HUP
  take_inhibit
  while true; do
    while IFS= read -r line; do
      case "${line}" in
        *'"member":"PrepareForShutdown"'*)
          if [[ "${line}" == *'[true]'* ]]; then
            cleanup
          fi
          ;;
        *'"member":"PrepareForSleep"'*)
          if [[ "${line}" == *'[true]'* ]]; then
            release_inhibit
          else
            take_inhibit
          fi
          ;;
      esac
    done < <(busctl --system --json=short monitor org.freedesktop.login1)
    if logind_flag PreparingForShutdown | grep -q true; then
      cleanup
    fi
    sleep 1
  done
}

enable_caffeine() {
  if is_active && inhibit_alive; then
    return 0
  fi
  if [[ -f "${PIDFILE}" ]]; then
    kill_tree "$(<"${PIDFILE}")"
    rm -f "${PIDFILE}"
  fi
  start_sleep_watch
  supervise &
  echo $! > "${PIDFILE}"
  disown || true
  echo "on" > "${STATEFILE}"
  notify "preferences-desktop-screensaver" "Caffeine on" "Idle lock disabled (lid still sleeps)"
}

disable_caffeine() {
  if [[ -f "${PIDFILE}" ]]; then
    kill_tree "$(<"${PIDFILE}")"
    rm -f "${PIDFILE}"
  fi
  echo "off" > "${STATEFILE}"
  start_swayidle
  notify "system-lock-screen" "Caffeine off" "Idle lock restored"
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
