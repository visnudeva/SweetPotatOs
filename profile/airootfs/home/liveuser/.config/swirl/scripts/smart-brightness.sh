#!/usr/bin/env bash
# Smart Brightness — max backlight for fullscreen video, then restore.
# Same idea as fullscreen-maxbright (GNOME). Uses real compositor fullscreen
# only (not Mod+m strip maximize). Does not re-clamp while active, so the
# brightness keys still work during a film.
#
# Usage:
#   smart-brightness.sh              # start the watcher (session exec)
#   smart-brightness.sh daemon       # same
#   smart-brightness.sh on|off|toggle|status
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${ROOT}/smart-brightness-lib.py"
TAG="sweetpotato-smart-brightness"
RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PIDFILE="${RUNTIME}/sweetpotato-smart-brightness.pid"
ACTIVEFILE="${RUNTIME}/sweetpotato-smart-brightness.active"
CONF_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/sweetpotatos/smart-brightness"
ENABLED_FILE="${CONF_DIR}/enabled"
SAVED_FILE="${CONF_DIR}/saved"

notify() {
  local title="$1" body="${2:-}"
  notify-send -t 2500 -a "Smart Brightness" -i "display-brightness-symbolic" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "${body}" 2>/dev/null || true
}

mkdir -p "${CONF_DIR}"

is_enabled() {
  local s=on
  if [[ -f "${ENABLED_FILE}" ]]; then
    s="$(tr -d '[:space:]' < "${ENABLED_FILE}" || true)"
  fi
  [[ "${s}" != "off" ]]
}

set_enabled() {
  printf '%s\n' "$1" > "${ENABLED_FILE}"
}

get_brightness() {
  brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,"",$4); print $4}'
}

set_brightness_percent() {
  local pct="$1"
  [[ -n "${pct}" ]] || return 0
  brightnessctl set "${pct}%" >/dev/null 2>&1 || true
}

is_active() {
  [[ -f "${ACTIVEFILE}" ]]
}

save_brightness() {
  local pct
  pct="$(get_brightness)"
  pct="${pct:-}"
  [[ -n "${pct}" ]] || return 0
  # Match the GNOME extension: only remember a real pre-max level.
  if (( pct < 99 )); then
    printf '%s\n' "${pct}" > "${SAVED_FILE}"
  fi
}

restore_brightness() {
  local pct=""
  if [[ -f "${SAVED_FILE}" ]]; then
    pct="$(tr -d '[:space:]' < "${SAVED_FILE}" || true)"
  fi
  [[ -n "${pct}" ]] || return 0
  set_brightness_percent "${pct}"
}

enter_video_mode() {
  if is_active; then
    return 0
  fi
  save_brightness
  : > "${ACTIVEFILE}"
  set_brightness_percent 100
}

exit_video_mode() {
  if ! is_active; then
    return 0
  fi
  rm -f "${ACTIVEFILE}"
  restore_brightness
}

should_activate() {
  command -v swaymsg >/dev/null 2>&1 || return 1
  [[ -f "${LIB}" ]] || return 1
  local answer
  answer="$(swaymsg -t get_tree 2>/dev/null | python3 "${LIB}" check-tree 2>/dev/null || echo 0)"
  [[ "${answer}" == "1" ]]
}

tick() {
  if ! is_enabled; then
    exit_video_mode
    return 0
  fi
  if should_activate; then
    enter_video_mode
  else
    exit_video_mode
  fi
}

kill_daemon() {
  local pid=""
  if [[ -f "${PIDFILE}" ]]; then
    pid="$(tr -d '[:space:]' < "${PIDFILE}" || true)"
  fi
  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    kill "${pid}" 2>/dev/null || true
    wait "${pid}" 2>/dev/null || true
  fi
  rm -f "${PIDFILE}"
}

run_daemon() {
  # One watcher per session.
  if [[ -f "${PIDFILE}" ]]; then
    local old
    old="$(tr -d '[:space:]' < "${PIDFILE}" || true)"
    if [[ -n "${old}" && "${old}" != "$$" ]] && kill -0 "${old}" 2>/dev/null; then
      exit 0
    fi
  fi
  printf '%s\n' "$$" > "${PIDFILE}"
  trap 'rm -f "${PIDFILE}"; exit_video_mode' EXIT INT TERM

  tick
  # window + workspace cover fullscreen and focus changes; poll as a backup.
  if command -v swaymsg >/dev/null 2>&1; then
    while true; do
      swaymsg -t subscribe -m '["window","workspace"]' 2>/dev/null | while IFS= read -r _; do
        tick
      done
      # subscribe ended (reload / compositor restart) — retry after a beat
      sleep 1
      tick
    done
  else
    while true; do
      tick
      sleep 1
    done
  fi
}

cmd="${1:-daemon}"
case "${cmd}" in
  daemon|start|"")
    run_daemon
    ;;
  on)
    set_enabled on
    notify "Smart Brightness on" "Fullscreen video goes to max backlight."
    # Nudge a running daemon via a no-op tick path: restart is simplest.
    if [[ -f "${PIDFILE}" ]]; then
      kill_daemon
    fi
    # Session already has exec; user toggle from a keybind should respawn.
    setsid "${ROOT}/smart-brightness.sh" daemon </dev/null >/dev/null 2>&1 &
    disown || true
    tick
    ;;
  off)
    set_enabled off
    exit_video_mode
    notify "Smart Brightness off" "Brightness stays where you set it."
    ;;
  toggle)
    if is_enabled; then
      exec "$0" off
    else
      exec "$0" on
    fi
    ;;
  status)
    if is_enabled; then
      if is_active; then
        printf 'on (video)\n'
      else
        printf 'on\n'
      fi
    else
      printf 'off\n'
    fi
    ;;
  tick)
    tick
    ;;
  *)
    echo "Usage: $0 [daemon|on|off|toggle|status]" >&2
    exit 1
    ;;
esac
