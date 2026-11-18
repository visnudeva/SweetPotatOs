#!/usr/bin/env bash
# Tray mode: classic GTK applets (icons) or light text-only status.
# State: ~/.config/sweetpotatos/tray-mode — "icons" (default) or "text".
# Usage: tray-mode.sh [icons|text|toggle|status|apply]
set -euo pipefail

ROOT="${SPO_CONFIG_ROOT:-${HOME}/.config}"
STATE_DIR="${ROOT}/sweetpotatos"
STATE_FILE="${STATE_DIR}/tray-mode"
TAG="sweetpotato-tray-mode"

notify() {
  local title="$1" body="$2"
  notify-send -t 2800 -a "Tray" \
    -h "string:x-canonical-private-synchronous:${TAG}" \
    -h "string:x-dunst-stack-tag:${TAG}" \
    "${title}" "${body}" || true
}

state_now() {
  if [[ -f "${STATE_FILE}" ]] && [[ "$(<"${STATE_FILE}")" == "text" ]]; then
    echo text
  else
    echo icons
  fi
}

write_state() {
  mkdir -p "${STATE_DIR}"
  printf '%s\n' "$1" >"${STATE_FILE}"
}

running() {
  pgrep -x "$1" >/dev/null 2>&1
}

start_bg() {
  # Avoid stacking duplicates across exec_always reloads.
  local bin="$1"
  shift
  command -v "${bin}" >/dev/null 2>&1 || return 0
  if running "${bin}"; then
    return 0
  fi
  "${bin}" "$@" >/dev/null 2>&1 &
  disown || true
}

stop_bins() {
  local bin
  for bin in "$@"; do
    if running "${bin}"; then
      pkill -x "${bin}" >/dev/null 2>&1 || true
    fi
  done
}

# udiskie: keep automount in both modes; only the tray icon is mode-specific.
ensure_udiskie() {
  local want_tray="$1" pid cmd=""
  command -v udiskie >/dev/null 2>&1 || return 0
  if running udiskie; then
    pid="$(pgrep -nx udiskie 2>/dev/null || true)"
    if [[ -n "${pid}" && -r "/proc/${pid}/cmdline" ]]; then
      cmd="$(tr '\0' ' ' <"/proc/${pid}/cmdline" 2>/dev/null || true)"
    fi
    if [[ "${want_tray}" == "yes" && "${cmd}" != *"--tray"* ]]; then
      stop_bins udiskie
    elif [[ "${want_tray}" == "no" && "${cmd}" == *"--tray"* ]]; then
      stop_bins udiskie
    else
      return 0
    fi
  fi
  if [[ "${want_tray}" == "yes" ]]; then
    start_bg udiskie --tray
  else
    start_bg udiskie
  fi
}

apply_icons() {
  ensure_udiskie yes
  start_bg nm-applet --indicator
  start_bg blueman-applet
}

apply_text() {
  stop_bins nm-applet blueman-applet
  ensure_udiskie no
}

apply_now() {
  case "$(state_now)" in
    text) apply_text ;;
    *) apply_icons ;;
  esac
}

cmd="${1:-toggle}"
case "${cmd}" in
  status)
    state_now
    ;;
  icons)
    write_state icons
    apply_now
    notify "tray icons" "Network, Bluetooth, and disks use the bar tray"
    ;;
  text)
    write_state text
    apply_now
    notify "light tray" "Text in the bar — use Settings for Network / Bluetooth"
    ;;
  apply)
    apply_now
    ;;
  toggle)
    if [[ "$(state_now)" == "text" ]]; then
      write_state icons
      apply_now
      notify "tray icons" "Network, Bluetooth, and disks use the bar tray"
    else
      write_state text
      apply_now
      notify "light tray" "Text in the bar — use Settings for Network / Bluetooth"
    fi
    ;;
  *)
    echo "Usage: $0 [icons|text|toggle|status|apply]" >&2
    exit 2
    ;;
esac
